-- DATA PROFILING: weekly_sales
-- ============================================
-- Goal: Identify anomalies, data quality issues, and distribution
-- patterns prior to ELT (Extract, Load, Transform).
-- This step ensures analytical accuracy and prevents silent errors
-- in downstream queries and the clean_weekly_sales table.
-- ============================================

-- ============================================
-- 1. DATA TYPE & SCHEMA VALIDATION
-- ============================================
-- Verifying column data types and nullability for schema integrity.
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH, 
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'weekly_sales';
-- Finding: week_date is VARCHAR — not DATE.
-- The format '31/8/20' (DD/MM/YY) does not follow SQL date standards.
-- Action Required: Convert using STR_TO_DATE(week_date, '%d/%m/%y')
--                 during clean_weekly_sales table creation.

-- ============================================
-- 2. DUPLICATE DETECTION
-- ============================================
-- Using ROW_NUMBER() partitioned by ALL columns to catch exact duplicates.
-- Partitioning by all columns ensures only 'hard' duplicates are flagged.
WITH duplicate_cte AS (
    SELECT *, 
        ROW_NUMBER() OVER(
            PARTITION BY week_date, region, platform, 
                         segment, customer_type, transactions, sales
        ) AS row_num
    FROM weekly_sales
)
SELECT * FROM duplicate_cte
WHERE row_num > 1;
-- Result: 0 duplicates found. Data ingestion integrity confirmed.

-- ============================================
-- 3. COMPLETENESS AUDIT (NULL / BLANK / STRING NULL)
-- ============================================
-- Checking for missing, empty, or placeholder 'null' string values.
-- Note: IN (NULL) does not catch actual NULLs in SQL.
--       Using IS NULL OR = 'null' OR = '' for complete coverage.
SELECT 
    SUM(CASE WHEN week_date IS NULL OR week_date = 'null' OR week_date = '' THEN 1 ELSE 0 END) AS week_date_nulls,
    SUM(CASE WHEN region IS NULL OR region = 'null' OR region = '' THEN 1 ELSE 0 END) AS region_nulls,
    SUM(CASE WHEN platform IS NULL OR platform = 'null' OR platform = '' THEN 1 ELSE 0 END) AS platform_nulls,
    SUM(CASE WHEN segment IS NULL OR segment = 'null' OR segment = '' THEN 1 ELSE 0 END) AS segment_nulls,
    SUM(CASE WHEN customer_type IS NULL OR customer_type = 'null' OR customer_type = '' THEN 1 ELSE 0 END) AS customer_type_nulls
FROM weekly_sales;
-- Result: 3,024 'null' string values found in segment column.
-- These are text placeholders, not actual SQL NULLs.
-- Action Required: Replace with 'Unknown' in clean_weekly_sales using CASE WHEN segment = 'null'.

-- ============================================
-- 4. CATEGORICAL DISTRIBUTION
-- ============================================
-- Checking distinct values per categorical column to validate
-- expected categories and spot any inconsistent entries.

SELECT DISTINCT region FROM weekly_sales;
-- Result: Multiple regions including Africa, Asia, Canada,
--         Europe, Oceania, South America, USA.

SELECT DISTINCT platform FROM weekly_sales;
-- Result: 2 platforms — Shopify, Retail.

SELECT DISTINCT segment FROM weekly_sales;
-- Result: C1, C2, C3, C4, F1, F2, F3, F4 + 'null' string values.
-- Segment format: Letter = demographic (C=Couples, F=Families)
--                Number = age band (1=Young Adults, 2=Middle Aged, 3/4=Retirees)

SELECT DISTINCT customer_type FROM weekly_sales;
-- Result: 3 types — New, Existing, Guest.

-- ============================================
-- 5. TEMPORAL BOUNDARY CHECK
-- ============================================
-- Validating the date range of the dataset.
-- Note: week_date is VARCHAR so ordering is string-based here.
SELECT 
    MIN(week_date) AS earliest_date,
    MAX(week_date) AS latest_date,
    COUNT(DISTINCT week_date) AS unique_weeks
FROM weekly_sales;
-- Action: After conversion to DATE — re-run this check on clean_weekly_sales.

-- ============================================
-- 6. UNEXPECTED VALUES & BUSINESS LOGIC CHECK
-- ============================================
-- Checking for zero sales which may indicate failed or test records.
SELECT * 
FROM weekly_sales
WHERE sales = 0;
-- Finding: 1 record found with sales = 0 in region 'South America'.
-- Possible cause: Failed transaction, system test, or data entry error.
-- Decision: Kept in clean_weekly_sales — filter in analysis queries if needed.
-- Note: avg_transactions for this row = 0/transactions which may cause issues.

-- ============================================
-- PROFILING SUMMARY
-- ============================================
-- | Check                  | Result                              |
-- |------------------------|-------------------------------------|
-- | Schema Validation      | week_date is VARCHAR — needs fix    |
-- | Duplicates             | 0 duplicates found                  |
-- | NULL Audit             | 3,024 'null' strings in segment     |
-- | Categorical Dist.      | 7 regions, 2 platforms, 8 segments  |
-- | Temporal Boundary(Date)| Re-check after date conversion      |
-- | Unexpected Values      | 1 zero sales record (South America) |
-- ============================================

-- ============================================
-- ACTION ITEMS BEFORE ANALYSIS
-- ============================================
-- 🔴 HIGH   → Convert week_date from VARCHAR to DATE using STR_TO_DATE
-- 🔴 HIGH   → Replace 'null' strings in segment with 'Unknown'
-- 🟡 MEDIUM → Derive age_band and demographic from segment column
-- 🟡 MEDIUM → Add week_number, month_number, calendar_year columns
-- 🟢 LOW    → Monitor zero sales record in analysis queries
-- ============================================
