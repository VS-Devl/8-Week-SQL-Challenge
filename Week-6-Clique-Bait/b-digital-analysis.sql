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
