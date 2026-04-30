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

