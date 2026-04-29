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

-- ============================================================
-- TABLE 4: page_hierarchy
-- ============================================================

-- Data Type and Schema Validation
DESCRIBE page_hierarchy;

SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns
WHERE table_name = 'page_hierarchy';

-- Full table inspection
SELECT * FROM page_hierarchy;
-- Result: 13 unique page_ids with page_name, product_category, product_id
-- Note: NULL values in product_category and product_id are EXPECTED —
--       non-product pages (Home Page, All Products, Checkout, Purchase)
--       do not have product information. These NULLs are business-valid.

-- ============================================================
-- TABLE 5: users
-- ============================================================

-- Data Type and Schema Validation
DESCRIBE users;

SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns
WHERE table_name = 'users';

-- Duplicate Check
WITH duplicates_cte AS (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY user_id, cookie_id, start_date) AS row_num
    FROM users
)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;
-- Result: No duplicates found

-- Granularity Check — CRITICAL FINDING
SELECT
    COUNT(DISTINCT user_id)   AS unique_users,
    COUNT(DISTINCT cookie_id) AS unique_cookies
FROM users;
-- Result: 500 unique users | 1782 unique cookie_ids
-- CRITICAL INSIGHT: One user averages 3-4 cookie_ids
-- This is EXPECTED behavior — users browse from multiple devices
-- and browsers (phone, laptop, incognito, Firefox, Chrome etc.)
-- Each device/browser session generates a NEW cookie_id
-- Rule: ALWAYS count user_id for people. NEVER count cookie_id — inflates by ~3.5x

-- Multi-Cookie User Check
-- Confirming that users genuinely have multiple cookies
SELECT user_id, COUNT(DISTINCT cookie_id) AS cookie_count
FROM users
GROUP BY user_id
HAVING cookie_count > 1
ORDER BY cookie_count DESC;
-- Result: Many users have multiple cookie_ids — confirmed expected behavior

-- Date Range Check
SELECT MAX(start_date), MIN(start_date)
FROM users;
-- Result: No sentinel or unrealistic dates in start_date


-- ============================================================
-- REFERENTIAL INTEGRITY CHECKS & ORPHAN RECORDS
-- ============================================================
-- Checking all foreign key relationships across tables
-- to ensure no orphan records exist in any direction
-- ============================================================

-- Check 1: users ↔ events via cookie_id
-- Matching count check
SELECT
    COUNT(DISTINCT e.cookie_id) AS events_cookies,
    COUNT(DISTINCT u.cookie_id) AS users_cookies
FROM users AS u
JOIN events AS e ON u.cookie_id = e.cookie_id;

-- Orphan check: cookies in users but not in events
SELECT u.cookie_id
FROM users AS u
LEFT JOIN events AS e ON u.cookie_id = e.cookie_id
WHERE e.cookie_id IS NULL;

-- Orphan check: cookies in events but not in users
SELECT e.cookie_id
FROM users AS u
RIGHT JOIN events AS e ON u.cookie_id = e.cookie_id
WHERE u.cookie_id IS NULL;
-- Result: No orphan records in either direction ✅

-- Check 2: page_hierarchy ↔ events via page_id
-- Matching count check
SELECT
    COUNT(DISTINCT e.page_id)  AS events_pages,
    COUNT(DISTINCT ph.page_id) AS hierarchy_pages
FROM events AS e
JOIN page_hierarchy AS ph ON e.page_id = ph.page_id;

-- Orphan check: page_ids in events but not in page_hierarchy
SELECT e.page_id
FROM events AS e
LEFT JOIN page_hierarchy AS ph ON e.page_id = ph.page_id
WHERE ph.page_id IS NULL;

-- Orphan check: page_ids in page_hierarchy but not in events
SELECT ph.page_id
FROM events AS e
RIGHT JOIN page_hierarchy AS ph ON e.page_id = ph.page_id
WHERE e.page_id IS NULL;
-- Result: No orphan records in either direction ✅

-- Check 3: event_identifier ↔ events via event_type
-- Matching count check
SELECT
    COUNT(DISTINCT e.event_type)  AS events_types,
    COUNT(DISTINCT ev.event_type) AS identifier_types
FROM events AS e
LEFT JOIN event_identifier AS ev ON e.event_type = ev.event_type;

-- Orphan check: event_types in events but not in event_identifier
SELECT e.event_type
FROM events AS e
LEFT JOIN event_identifier AS ev ON e.event_type = ev.event_type
WHERE ev.event_type IS NULL;

-- Orphan check: event_types in event_identifier but not in events
SELECT ev.event_type
FROM events AS e
RIGHT JOIN event_identifier AS ev ON e.event_type = ev.event_type
WHERE e.event_type IS NULL;
-- Result: No orphan records in either direction ✅
