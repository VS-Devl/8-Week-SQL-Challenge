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

