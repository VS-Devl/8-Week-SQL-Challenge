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

