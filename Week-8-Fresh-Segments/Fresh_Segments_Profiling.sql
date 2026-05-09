-- ============================================================
-- DATA PROFILING — INTEREST_METRICS & INTEREST_MAP TABLES
-- ============================================================

-- ============================================================
-- TABLE: INTEREST_METRICS
-- ============================================================

-- 1. DATA TYPE AND SCHEMA VALIDATION
SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns
WHERE table_name = 'interest_metrics';
-- _month, _year, month_year and interest_id are stored as VARCHAR
-- these need to be fixed during the data cleaning phase


-- 2. DUPLICATE CHECK
WITH duplicate_cte AS (
    SELECT *, 
           ROW_NUMBER() OVER(PARTITION BY _month, _year, month_year, interest_id, 
                             composition, index_value, ranking, percentile_ranking) AS row_num
    FROM interest_metrics
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
-- Result: 30 exact duplicate rows found — to be removed during cleaning


-- 3. CATEGORICAL CHECK
SELECT DISTINCT _month FROM interest_metrics ORDER BY _month DESC;
-- NULL string value found — needs to be converted to actual NULL

SELECT DISTINCT _year FROM interest_metrics ORDER BY _year DESC;
-- NULL string value found — needs to be converted to actual NULL

SELECT DISTINCT month_year FROM interest_metrics ORDER BY month_year DESC;
-- NULL string value found — needs to be converted to actual NULL

SELECT DISTINCT interest_id FROM interest_metrics ORDER BY interest_id DESC;
-- NULL string value found — needs to be converted to actual NULL

SELECT DISTINCT composition FROM interest_metrics ORDER BY composition;
-- No inconsistent values, no NULL strings, no zero values

SELECT DISTINCT index_value FROM interest_metrics ORDER BY index_value;
-- No inconsistent data found

SELECT DISTINCT ranking FROM interest_metrics ORDER BY ranking;
-- No inconsistent data found

SELECT DISTINCT percentile_ranking FROM interest_metrics ORDER BY percentile_ranking;
-- A 0 value exists but is valid — percentile rank ranges between 0 and 1


-- 4. DATE RANGES
-- Date range check will be performed after fixing data types
-- and converting month_year to proper date format during cleaning


-- 5. NULL / BLANK VALUES CHECK
SELECT 
    SUM(CASE WHEN _month = 'NULL' THEN 1 ELSE 0 END)      AS month_null,
    SUM(CASE WHEN _year = 'NULL' THEN 1 ELSE 0 END)       AS year_null,
    SUM(CASE WHEN month_year = 'NULL' THEN 1 ELSE 0 END)  AS month_year_null,
    SUM(CASE WHEN interest_id = 'NULL' THEN 1 ELSE 0 END) AS id_null
FROM interest_metrics;
-- _month, _year, month_year each have 1194 NULL string values
-- interest_id has 1193 NULL string values
-- The 1 difference is because one row has a valid interest_id but NULL date values
-- This is a data pipeline error — date was lost during ingestion


-- 6. GRANULARITY CHECK
SELECT COUNT(*), COUNT(DISTINCT interest_id) 
FROM interest_metrics;
-- 14273 total rows, 1203 unique interest_ids
-- One row = one interest_id in one specific month/year combination
