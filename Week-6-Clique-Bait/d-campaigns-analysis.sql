-- Section D: Campaigns Analysis
-- ============================================================
-- Approach: Build one reference table (final_data) first,
-- then run all campaign insights on top of it.
-- Key technique: LEFT JOIN campaign_identifier on BETWEEN
-- condition to map visit start times to campaign periods.
-- ============================================================


-- ============================================================
-- REFERENCE TABLE: final_data
-- One row per unique visit_id with all metrics
-- ============================================================
-- Columns:
--   visit_id         → unique visit identifier
--   user_id          → actual user (NOT cookie_id — avoids 3.5x inflation)
--   event_start_time → MIN(event_time) — earliest event in the visit
--   page_views       → count of page view events per visit
--   cart_adds        → count of add to cart events per visit
--   purchase_flag    → 1 if visit had a purchase, 0 if not
--                      MAX() used — safer than COUNT() for binary flags
--                      MAX(0,0,1) = 1 | MAX(0,0,0) = 0 always
--   impression       → count of ad impression events per visit
--   click            → count of ad click events per visit
--   campaign_name    → matched via LEFT JOIN on BETWEEN date range
--                      COALESCE handles visits outside campaign periods
--   cart_products    → GROUP_CONCAT ordered by sequence_number
--                      shows products added to cart in visit order
-- ============================================================
-- Why CTE before LEFT JOIN?
-- MIN(event_time) is an aggregate — cannot be used directly
-- in a JOIN condition. CTE pre-calculates it first, then
-- final SELECT joins on the pre-calculated value.
-- ============================================================

CREATE TABLE final_data AS
WITH mid_cte AS (
    SELECT
        ev.visit_id,
        us.user_id,
        MIN(event_time)                                                          AS event_start_time,
        COUNT(CASE WHEN ef.event_name = 'Page View'     THEN ev.visit_id END)   AS page_views,
        COUNT(CASE WHEN ef.event_name = 'Add to Cart'   THEN ev.visit_id END)   AS cart_adds,
        MAX(CASE WHEN ef.event_name = 'Purchase'        THEN 1 ELSE 0 END)      AS purchase_flag,
        COUNT(CASE WHEN ef.event_name = 'Ad Impression' THEN ev.visit_id END)   AS impression,
        COUNT(CASE WHEN ef.event_name = 'Ad Click'      THEN ev.visit_id END)   AS click,
        -- cart_products: comma separated list of products added to cart
        -- ordered by sequence_number to show the journey order
        GROUP_CONCAT(
            CASE WHEN ef.event_name = 'Add to Cart' THEN ph.page_name END
            ORDER BY ev.sequence_number
            SEPARATOR ', '
        )                                                                        AS cart_products
    FROM events          AS ev
    JOIN users           AS us ON ev.cookie_id    = us.cookie_id
    JOIN event_identifier AS ef ON ev.event_type  = ef.event_type
    JOIN page_hierarchy  AS ph ON ev.page_id      = ph.page_id
    GROUP BY ev.visit_id, us.user_id
)
SELECT
    mc.visit_id,
    mc.user_id,
    mc.event_start_time,
    mc.page_views,
    mc.cart_adds,
    mc.purchase_flag,
    COALESCE(ci.campaign_name, 'No Campaign')   AS campaign_name,
    mc.impression,
    mc.click,
    mc.cart_products
FROM mid_cte              AS mc
LEFT JOIN campaign_identifier AS ci
    ON mc.event_start_time BETWEEN ci.start_date AND ci.end_date;
-- LEFT JOIN used — not all visits fall within a campaign period
-- COALESCE replaces NULL campaign_name with 'No Campaign'

-- Sample row:
-- 001597 | 155 | 2020-02-17 00:21:45 | 10 | 6 | 1
-- | Half Off - Treat Your Shellf(ish) | 1 | 1
-- | Salmon, Russian Caviar, Black Truffle, Lobster, Crab, Oyster

-- ============================================================
-- BONUS: Normalize campaign_identifier.products
-- The products column stores denormalized ranges like "1-3"
-- meaning product IDs 1, 2, AND 3 — not just 1 and 3
-- ============================================================

-- Attempt 1: JSON_TABLE approach
-- Converts "1-3" to ["1","3"] — only extracts endpoints, misses middle values
SELECT
    jt.product_id,
    ph.page_name,
    ph.product_category,
    ci.campaign_name
FROM campaign_identifier AS ci
CROSS JOIN JSON_TABLE(
    CONCAT('["', REPLACE(products, '-', '", "'), '"]'),
    '$[*]' COLUMNS (product_id TEXT PATH '$')
) AS jt
JOIN page_hierarchy AS ph ON ph.product_id = jt.product_id;

-- Attempt 2: Recursive CTE approach (correct solution)
-- Extracts start and end of range, generates ALL numbers between them
-- LEFT(products, 1) → start number | RIGHT(products, 1) → end number
-- Recursive member increments by 1 until start = end
WITH RECURSIVE first_cte AS (
    SELECT
        LEFT(products, 1)  AS first_chr,   -- start of range e.g. 1
        RIGHT(products, 1) AS last_chr,    -- end of range e.g. 3
        campaign_id,
        campaign_name,
        start_date,
        end_date
    FROM campaign_identifier
),
mid_cte AS (
    -- Anchor: start from first_chr
    SELECT first_chr, last_chr, campaign_id, campaign_name, start_date, end_date
    FROM first_cte
    UNION ALL
    -- Recursive: increment by 1 until first_chr = last_chr
    SELECT first_chr + 1, last_chr, campaign_id, campaign_name, start_date, end_date
    FROM mid_cte
    WHERE first_chr < last_chr
)
SELECT
    first_chr  AS product_id,
    campaign_id,
    campaign_name,
    start_date,
    end_date
FROM mid_cte
ORDER BY product_id;
-- Result: "1-3" correctly expands to product_ids 1, 2, 3
-- Can be joined with page_hierarchy to get product names per campaign

