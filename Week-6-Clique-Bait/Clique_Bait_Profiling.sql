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
