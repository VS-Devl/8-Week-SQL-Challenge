-- Week 6 — Clique Bait
-- Data Profiling & Quality Audit — All 5 Tables
-- ============================================================
-- PROFILING SUMMARY
-- campaign_identifier → Clean. No duplicates, no sentinel dates,
--                        no overlapping campaigns
-- event_identifier    → Clean. Small lookup table (5 rows), verified manually
-- events              → Clean. 1782 cookie_ids, 32734 activities,
--                        sequences valid (start at 1, no gaps)
-- page_hierarchy      → Clean. NULLs in category columns are EXPECTED
--                        (non-product pages like Home, Checkout, Purchase)
-- users               → Clean. 500 unique users with 1782 cookie_ids
--                        One user averages 3-4 cookies (multiple devices/browsers)
--                        ALWAYS use user_id for people counts
--                        NEVER use cookie_id — inflates count by ~3.5x
-- ============================================================
-- TABLE 1: campaign_identifier
-- ============================================================

-- Data Type and Schema Validation
DESCRIBE campaign_identifier;

SELECT column_name, is_nullable, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'campaign_identifier';

-- Logical Date Integrity
-- Check if end_date is ever less than start_date (impossible date range)
SELECT *
FROM campaign_identifier
WHERE end_date < start_date;
-- Result: No such records — date ranges are logically valid

-- Date Range Check
-- Looking for sentinel values like '9999-12-31' or unrealistic dates
SELECT MAX(start_date), MIN(start_date), MAX(end_date), MIN(end_date)
FROM campaign_identifier;
-- Result: No sentinel or unrealistic dates found

-- Overlapping Campaign Check
-- Two campaigns overlap when end_date of one exceeds start_date of the next
-- Using LEAD() to compare each campaign's end_date with next campaign's start_date
WITH date_cte AS (
    SELECT *,
        LEAD(start_date) OVER(ORDER BY campaign_id) AS next_campaign_start
    FROM campaign_identifier
)
SELECT *
FROM date_cte
WHERE end_date > next_campaign_start;
-- Result: No overlapping campaigns — each campaign runs in its own window

-- ============================================================
-- TABLE 2: event_identifier
-- ============================================================

-- Data Type and Schema Validation
DESCRIBE event_identifier;

SELECT column_name, is_nullable, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'event_identifier';

-- Full table inspection (only 5 rows — no further checks needed)
SELECT * FROM event_identifier;
-- Result: 5 event types, all clean, no nulls, no anomalies

-- ============================================================
-- TABLE 3: events
-- ============================================================

-- Data Type and Schema Validation
DESCRIBE events;

SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns
WHERE table_name = 'events';

-- Duplicate Check
-- Partitioning by all meaningful columns to detect true duplicates
WITH duplicate_cte AS (
    SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY visit_id, cookie_id, page_id, event_type,
                         sequence_number, event_time
        ) AS row_num
    FROM events
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
-- Result: No duplicates found

-- Date Range Check
-- Checking for sentinel values or future/unrealistic dates
SELECT MAX(event_time), MIN(event_time)
FROM events;
-- Result: No sentinel or unrealistic dates found

-- Granularity Check
-- Understanding the grain of this table
SELECT
    COUNT(DISTINCT cookie_id) AS unique_cookies,
    COUNT(*) AS total_activities
FROM events;
-- Result: 1782 unique cookie_ids | 32734 total activities
-- Note: cookie_id ≠ user. Use user_id from users table for actual people counts.

-- Categorical Distribution Checks
-- These will also be used for referential integrity checks below
SELECT DISTINCT event_type FROM events;                        -- 5 unique event types
SELECT DISTINCT page_id FROM events ORDER BY page_id;         -- 13 unique page_ids
SELECT COUNT(DISTINCT cookie_id) FROM events;                 -- 1782 unique cookie_ids

-- Sequence Number Validation
-- Step 1: All visit_ids must start their sequence at 1
SELECT visit_id, MIN(sequence_number) AS first_seq
FROM events
GROUP BY visit_id
HAVING first_seq != 1;
-- Result: All sequences correctly start at 1

-- Step 2: No gaps in sequence — max sequence must equal total steps
SELECT visit_id, MAX(sequence_number) AS last_seq, COUNT(*) AS total_steps
FROM events
GROUP BY visit_id
HAVING total_steps != last_seq;
-- Result: No gaps in any sequence — funneling is intact

-- NULL / Blank / Corrupted Value Audit
SELECT
    SUM(CASE WHEN visit_id IS NULL OR visit_id = '' OR visit_id = 'null'
        THEN 1 ELSE 0 END)        AS visit_null,
    SUM(CASE WHEN cookie_id IS NULL OR cookie_id = '' OR cookie_id = 'null'
        THEN 1 ELSE 0 END)        AS cookie_null,
    SUM(CASE WHEN page_id IS NULL OR page_id = '' OR page_id = 'null'
        THEN 1 ELSE 0 END)        AS page_null,
    SUM(CASE WHEN event_type IS NULL OR event_type = '' OR event_type = 'null'
        THEN 1 ELSE 0 END)        AS event_type_null,
    SUM(CASE WHEN sequence_number IS NULL OR sequence_number = '' OR sequence_number = 'null'
        THEN 1 ELSE 0 END)        AS sequence_null,
    SUM(CASE WHEN event_time IS NULL
        THEN 1 ELSE 0 END)        AS time_null
FROM events;
-- Result: No NULL, blank, or corrupted values found in any column
