-- Section B: Digital Analysis
-- ============================================================
-- Key Mental Model for Clique Bait:
-- Always think at the VISIT level — not the row level.
-- A visit is a journey. A row is just one step in that journey.
-- One visit_id can have multiple events (page view, add to cart, purchase)
-- ============================================================


-- ============================================================
-- Q1: How many users are there?
-- ============================================================
-- Rule: ALWAYS use user_id for people counts
--       cookie_id tracks devices/sessions not humans
-- ============================================================

SELECT COUNT(DISTINCT user_id) AS total_users
FROM users;

-- Result: 500 unique users

-- ============================================================
-- Q2: How many cookies does each user have on average?
-- ============================================================
-- Why CTE? In MySQL you cannot nest aggregate functions directly.
-- AVG(COUNT(*)) throws "Invalid use of group function" error.
-- Solution: First COUNT per user in CTE, then AVG in outer query.
-- ============================================================

WITH avg_cte AS (
    SELECT user_id, COUNT(*) AS users_cookie
    FROM users
    GROUP BY user_id
)
SELECT ROUND(AVG(users_cookie), 2) AS avg_cookies_per_user
FROM avg_cte;

-- Result: 3.56 cookies per user on average
-- Confirms profiling finding: one user = multiple devices/browsers

-- ============================================================
-- Q3: What is the unique number of visits by all users per month?
-- ============================================================

SELECT
    MONTH(event_time) AS date_month,
    COUNT(DISTINCT visit_id) AS total_visits
FROM events
GROUP BY date_month;

-- Result: February has highest visits — possible seasonal peak
-- Seafood demand may peak in certain months for fishing season

-- ============================================================
-- Q4: What is the number of events for each event type?
-- ============================================================
-- Note: Joining event_identifier to show readable names
--       instead of raw event_type numbers
-- ============================================================

SELECT
    ef.event_name,
    COUNT(*) AS total_events
FROM events AS e
JOIN event_identifier AS ef ON e.event_type = ef.event_type
GROUP BY ef.event_name;

-- Result: Page View is highest — every visit starts with at least one
-- Natural funnel: Page View → Add to Cart → Purchase

