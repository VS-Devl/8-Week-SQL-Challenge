-- Section C: Product Funnel Analysis
-- ============================================================

-- ============================================================
-- REFERENCE TABLE 1: Products
-- Metrics per individual product
-- ============================================================
-- Structure:
--   products_cte  → page views + cart adds using CASE WHEN
--   added_cte     → all products added to cart (visit + product)
--   purchase_cte  → all visits that completed a purchase
--   abundun_cte   → cart adds RIGHT JOIN purchases, IS NULL = abandoned
--   sold_cte      → cart adds INNER JOIN purchases = purchased
-- Final → JOIN all 4 metrics together per product
-- ============================================================

CREATE TABLE products AS
WITH products_cte AS (
    -- Page views and cart adds per product in one pass using CASE WHEN
    -- COUNT ignores NULLs — no ELSE needed when condition is FALSE
    SELECT
        ph.page_name,
        COUNT(CASE WHEN ef.event_name = 'Page View'   THEN ph.page_name END) AS product_viewed,
        COUNT(CASE WHEN ef.event_name = 'Add to Cart' THEN ph.page_name END) AS product_in_cart
    FROM events AS ev
    JOIN page_hierarchy    AS ph ON ev.page_id    = ph.page_id
    JOIN event_identifier  AS ef ON ev.event_type = ef.event_type
    WHERE ph.product_category IS NOT NULL   -- exclude non-product pages
    GROUP BY ph.page_name
),
added_cte AS (
    -- All products added to cart — capturing visit_id + product name
    SELECT ev.visit_id, ph.page_name
    FROM events AS ev
    JOIN event_identifier AS ef ON ev.event_type = ef.event_type
    JOIN page_hierarchy   AS ph ON ev.page_id    = ph.page_id
    WHERE ef.event_name = 'Add to Cart'
),
purchase_cte AS (
    -- All visits that completed a purchase
    SELECT ev.visit_id, ph.page_name
    FROM events AS ev
    JOIN event_identifier AS ef ON ev.event_type = ef.event_type
    JOIN page_hierarchy   AS ph ON ev.page_id    = ph.page_id
    WHERE ef.event_name = 'Purchase'
),
abundun_cte AS (
    -- Abandoned: added to cart BUT visit never had a purchase
    -- RIGHT JOIN keeps all cart additions, IS NULL filters non-purchasers
    SELECT
        ac.page_name,
        COUNT(ac.visit_id) AS product_abunduned
    FROM purchase_cte AS pc
    RIGHT JOIN added_cte AS ac ON pc.visit_id = ac.visit_id
    WHERE pc.visit_id IS NULL
    GROUP BY ac.page_name
),
sold_cte AS (
    -- Purchased: added to cart AND visit completed a purchase
    -- INNER JOIN keeps only matching visit_ids
    SELECT
        ac.page_name,
        COUNT(ac.visit_id) AS product_purchased
    FROM purchase_cte AS pc
    JOIN added_cte    AS ac ON pc.visit_id = ac.visit_id
    GROUP BY ac.page_name
)
-- Final: combine all 4 metrics per product
SELECT
    pro.page_name,
    pro.product_viewed,
    pro.product_in_cart,
    ac.product_abunduned,
    sc.product_purchased
FROM products_cte AS pro
JOIN abundun_cte  AS ac ON pro.page_name = ac.page_name
JOIN sold_cte     AS sc ON pro.page_name = sc.page_name;

-- Results:
-- Lobster        1547  968  214  754
-- Crab           1564  949  230  719
-- Oyster         1568  943  217  726
-- Kingfish       1559  920  213  707
-- Black Truffle  1469  924  217  707
-- Tuna           1515  931  234  697
-- Russian Caviar 1563  946  249  697
-- Salmon         1559  938  227  711
-- Abalone        1525  932  233  699
