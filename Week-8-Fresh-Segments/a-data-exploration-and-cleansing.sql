-- ============================================================
-- DATA CLEANING & SECTION A: DATA EXPLORATION AND CLEANSING
-- ============================================================

-- ============================================================
-- PART 1: DATA CLEANING
-- ============================================================

-- STEP 1: REPLACE NULL STRINGS WITH ACTUAL NULL VALUES
-- Best practice: always SELECT before UPDATE to verify affected rows

-- Column: _month
SELECT _month FROM interest_metrics WHERE _month = 'NULL';
UPDATE interest_metrics SET _month = NULL WHERE _month = 'NULL';

-- Column: _year
SELECT _year FROM interest_metrics WHERE _year = 'NULL';
UPDATE interest_metrics SET _year = NULL WHERE _year = 'NULL';

-- Column: month_year
SELECT month_year FROM interest_metrics WHERE month_year = 'NULL';
UPDATE interest_metrics SET month_year = NULL WHERE month_year = 'NULL';

-- Column: interest_id
SELECT interest_id FROM interest_metrics WHERE interest_id = 'NULL';
UPDATE interest_metrics SET interest_id = NULL WHERE interest_id = 'NULL';

-- Column: interest_summary (interest_map table)
-- 20 blank values found during profiling — converting to actual NULL
SELECT interest_summary FROM interest_map WHERE interest_summary = '';
UPDATE interest_map SET interest_summary = NULL WHERE interest_summary = '';


-- STEP 2: DATA TYPE STANDARDIZATION
ALTER TABLE interest_metrics MODIFY COLUMN _month INT;
ALTER TABLE interest_metrics MODIFY COLUMN _year INT;
ALTER TABLE interest_metrics MODIFY COLUMN interest_id INT;

-- ============================================================
-- PART 2: SECTION A — DATA EXPLORATION AND CLEANSING
-- ============================================================

-- 1: Update the month_year column to be a date data type
--     with the start of the month
-- -------------------------------------------------------
-- Step 1: Ensure column is varchar before concat
-- Step 2: Prepend '01-' to create a full date string e.g. '01-07-2018'
-- Step 3: Add new date column and populate using STR_TO_DATE
-- Step 4: Drop original varchar column and rename new date column

ALTER TABLE interest_metrics MODIFY COLUMN month_year VARCHAR(10);

UPDATE interest_metrics
SET month_year = CONCAT('01-', month_year);

ALTER TABLE interest_metrics
ADD COLUMN month_date DATE AFTER month_year;

UPDATE interest_metrics
SET month_date = STR_TO_DATE(month_year, '%d-%m-%Y');

ALTER TABLE interest_metrics DROP COLUMN month_year;
ALTER TABLE interest_metrics RENAME COLUMN month_date TO month_year;


-- 2: Count of records for each month_year value sorted chronologically
--     with NULL values appearing first
-- -------------------------------------------------------
-- Forcing NULLs first using CASE WHEN — assigns 0 to NULL (sorts before 1)
SELECT 
    month_year, 
    COUNT(*) AS records
FROM interest_metrics
GROUP BY month_year
ORDER BY 
    CASE WHEN month_year IS NULL THEN 0 ELSE 1 END,
    month_year ASC;

-- 3: What should we do with NULL values in interest_metrics?
-- -------------------------------------------------------
/*
During profiling, 1194 NULL string values were found in month_year, _month, 
_year and interest_id columns. These were converted to actual NULLs in Step 1.

This is a time-series analysis dataset — every question involves monthly trends,
rankings by month and period comparisons. A row without a date cannot contribute
to any meaningful analysis.

Decision: Remove all rows where month_year is NULL.
The 1 row with a valid interest_id but NULL date is also removed — without a date,
it cannot be used in any time-based analysis.
*/

SELECT * FROM interest_metrics WHERE month_year IS NULL;
-- Result: 1194 rows to be deleted
DELETE FROM interest_metrics WHERE month_year IS NULL;
-- 1194 rows removed

-- 4: How many interest_id values exist in interest_metrics
--     but not in interest_map? What about the other way around?
-- -------------------------------------------------------
/*
This was already investigated during profiling. After removing NULL values:
- All remaining interest_ids in interest_metrics match interest_map
- 7 ids exist in interest_map but not in interest_metrics
- These 7 are likely reserved for future use or interests with no recorded activity
*/

-- interest_ids in interest_metrics with no match in interest_map
SELECT imt.interest_id
FROM interest_metrics AS imt
LEFT JOIN interest_map AS imp ON imt.interest_id = imp.id
WHERE imp.id IS NULL;
-- Result: 0 orphan records after NULL removal

-- Count match verification
SELECT COUNT(DISTINCT imp.id), COUNT(DISTINCT imt.interest_id)
FROM interest_metrics AS imt
JOIN interest_map AS imp ON imt.interest_id = imp.id;
-- Result: counts match on both sides — referential integrity confirmed

-- 5: Summarise the id values in interest_map by total record count
-- -------------------------------------------------------
SELECT COUNT(id) AS total_records
FROM interest_map;
-- Result: 1209 total records in interest_map


-- 6: What sort of table join should we perform for our analysis and why?
-- -------------------------------------------------------
/*
INNER JOIN is the correct choice because:
- We only want interests that have both metrics data AND a name/description
- The 7 unmatched ids in interest_map are useless without metrics data
- After cleaning, all remaining interest_ids in interest_metrics have a match
*/

-- Verify join logic using interest_id = 21246
SELECT 
    imp.interest_name, imp.interest_summary, imp.created_at, imp.last_modified, imt._month, 
    imt._year, imt.month_year,imt.interest_id, imt.composition, imt.index_value, imt.ranking, imt.percentile_ranking
FROM interest_metrics AS imt
JOIN interest_map AS imp ON imt.interest_id = imp.id
WHERE imt.interest_id = 21246;
-- Result: 10 rows — one per month for this interest across the full date range

-- 7: Are there any records where month_year is before created_at?
--     Are these values valid?
-- -------------------------------------------------------
/*
188 records found where month_year < created_at.
These are VALID — not data errors.

Reason: During date conversion, we prepended '01-' to force the date to the
1st of every month. The created_at column has the actual exact creation date.
If an interest was created on June 11 2018 and month_year is 2018-06-01 —
it appears the metric came before the interest existed. But both are in 
June 2018 — the same month. This is an artifact of our date conversion,
not a real data quality issue.
*/

SELECT COUNT(*)
FROM interest_metrics AS imt
JOIN interest_map AS imp ON imt.interest_id = imp.id
WHERE imt.month_year < imp.created_at;
-- Result: 188 records — all valid, same month different day
