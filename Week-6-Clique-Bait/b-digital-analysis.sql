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


-- ============================================================
-- Q5: What is the percentage of visits which have a purchase event?
-- ============================================================
-- Formula : purchase visits / total unique visits * 100
-- Key     : Denominator must be COUNT(DISTINCT visit_id) not COUNT(*)
--           COUNT(*) counts all events — inflates denominator
-- ============================================================

WITH percent_cte AS (
    SELECT COUNT(*) AS total_purchase
    FROM events AS e
    JOIN event_identifier AS ef ON e.event_type = ef.event_type
    WHERE ef.event_name = 'Purchase'
)
SELECT ROUND(
    total_purchase / (SELECT COUNT(DISTINCT visit_id) FROM events) * 100,
    2
) AS purchase_percent
FROM percent_cte;

-- Result: 49.86% of visits result in a purchase
-- Strong conversion rate for an online store

-- ============================================================
-- Q6: What is the percentage of visits which view the checkout
--     page but do not have a purchase event?
-- ============================================================
-- Pattern : "Find visits that did X but never did Y"
--   Step 1 → CTE of all visit_ids that viewed checkout
--   Step 2 → CTE of all visit_ids that had a purchase
--   Step 3 → RIGHT JOIN + IS NULL = checkout visits without purchase
-- Key Insight: Think at VISIT level not ROW level
--   Wrong → WHERE event_type != purchase (filters rows, not visits)
--   Right  → LEFT/RIGHT JOIN to compare visit_id lists
-- ============================================================

WITH checkout_cte AS (
    -- All visits that viewed the checkout page
    SELECT ev.visit_id
    FROM events AS ev
    JOIN page_hierarchy AS ph ON ev.page_id = ph.page_id
    WHERE ph.page_name = 'Checkout'
),
purchase_cte AS (
    -- All visits that completed a purchase
    SELECT e.visit_id
    FROM events AS e
    JOIN event_identifier AS ef ON e.event_type = ef.event_type
    WHERE ef.event_name = 'Purchase'
),
percent_cte AS (
    -- Checkout visits with NO matching purchase visit_id = abandoned
    SELECT COUNT(cc.visit_id) AS checkout_visits
    FROM purchase_cte AS pc
    RIGHT JOIN checkout_cte AS cc ON pc.visit_id = cc.visit_id
    WHERE pc.visit_id IS NULL
)
SELECT ROUND(
    checkout_visits / (SELECT COUNT(DISTINCT visit_id) FROM events) * 100,
    2
) AS abandonment_percent
FROM percent_cte;

-- Result: 9.15% of visits reach checkout but don't purchase
-- Business Insight: Cart abandonment — these are warm leads
-- Recommendation: Investigate checkout friction, consider
-- abandonment email campaigns to recover these visits

-- ============================================================
-- Q7: What are the top 3 pages by number of views?
-- ============================================================

SELECT
    pge.page_name,
    COUNT(*) AS total_views
FROM events AS evt
JOIN page_hierarchy AS pge ON evt.page_id = pge.page_id
GROUP BY pge.page_name
ORDER BY total_views DESC
LIMIT 3;

-- Result: All Products, Lobster, Crab are top 3
-- Shellfish products dominate page views

-- ============================================================
-- Q8: What is the number of views and cart adds
--     for each product category?
-- ============================================================
-- Pattern : COUNT(CASE WHEN condition THEN value END)
--   Why no ELSE? COUNT ignores NULL values automatically.
--   When condition is FALSE → implicit NULL → not counted.
--   No need for ELSE 0 unlike SUM pattern.
-- ============================================================

SELECT
    ph.product_category,
    COUNT(CASE WHEN ef.event_name = 'Page View'    THEN ph.product_category END) AS total_views,
    COUNT(CASE WHEN ef.event_name = 'Add to Cart'  THEN ph.product_category END) AS cart_adds
FROM events AS e
JOIN event_identifier AS ef ON e.event_type = ef.event_type
JOIN page_hierarchy   AS ph ON e.page_id    = ph.page_id
WHERE ph.product_category IS NOT NULL
GROUP BY ph.product_category
ORDER BY 2 DESC;

-- Result: Shellfish dominates both views and cart adds
-- Consistent with Q7 — Lobster and Crab are hero products


-- ============================================================
-- Q9: What are the top 3 products by purchases?
-- ============================================================
-- Key Insight: Purchase event happens on confirmation page
--   NOT on the product page — so we can't just count purchase events
--   per product directly.
-- Solution:
--   CTE 1 → products that were Added to Cart (which visit + which product)
--   CTE 2 → visits that completed a Purchase
--   JOIN on visit_id → products in cart that also had a purchase = purchased!
-- ============================================================

WITH cart_cte AS (
    -- Products added to cart — capturing visit_id + product name
    SELECT
        ev.visit_id,
        pg.page_name
    FROM events AS ev
    JOIN page_hierarchy    AS pg ON ev.page_id    = pg.page_id
    JOIN event_identifier  AS ef ON ev.event_type = ef.event_type
    WHERE ef.event_name = 'Add to Cart'
),
purchase_cte AS (
    -- Visits that completed a purchase
    SELECT ev.visit_id
    FROM events AS ev
    JOIN event_identifier AS ef ON ev.event_type = ef.event_type
    WHERE ef.event_name = 'Purchase'
)
SELECT
    cc.page_name,
    COUNT(*) AS total_purchases
FROM cart_cte    AS cc
JOIN purchase_cte AS pc ON cc.visit_id = pc.visit_id
GROUP BY cc.page_name
ORDER BY total_purchases DESC
LIMIT 3;

-- Result: Lobster 754 | Oyster 726 | Crab 719
-- All shellfish — consistent finding across Q7, Q8, Q9
-- Shellfish is the hero category driving Clique Bait's business
