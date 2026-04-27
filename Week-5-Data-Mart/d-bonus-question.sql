-- Section D: Bonus Question
-- ============================================================
-- BONUS: Which areas have highest negative impact in 2020?
--        12 week before and after analysis by dimension
--   Dimensions analyzed: region, platform, age_band, demographic, customer_type
-- ============================================================

-- Dimension 1: Region
WITH before_cte AS (
    SELECT region, SUM(sales) AS before_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-03-23' AND week_date < '2020-06-15'
    GROUP BY region
),
after_cte AS (
    SELECT region, SUM(sales) AS after_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-06-15' AND week_date < '2020-09-07'
    GROUP BY region
)
SELECT
    '12 Week Window'                                                         AS window_type,
    ac.region,
    be.before_sales,
    ac.after_sales,
    ac.after_sales - be.before_sales                                         AS actual_growth,
    ROUND(((ac.after_sales - be.before_sales) / be.before_sales) * 100, 2)  AS growth_rate
FROM after_cte  AS ac
JOIN before_cte AS be ON ac.region = be.region
ORDER BY growth_rate;

-- Results: Asia -3.26% | Oceania -3.03% | Europe +4.73% (outlier)
-- Insight: Europe growing — likely due to higher environmental awareness
--          Asia/Oceania most resistant to packaging change

-- Dimension 2: Platform
WITH before_cte AS (
    SELECT platform, SUM(sales) AS before_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-03-23' AND week_date < '2020-06-15'
    GROUP BY platform
),
after_cte AS (
    SELECT platform, SUM(sales) AS after_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-06-15' AND week_date < '2020-09-07'
    GROUP BY platform
)
SELECT
    '12 Week Window'                                                         AS window_type,
    ac.platform,
    be.before_sales,
    ac.after_sales,
    ac.after_sales - be.before_sales                                         AS actual_growth,
    ROUND(((ac.after_sales - be.before_sales) / be.before_sales) * 100, 2)  AS growth_rate
FROM after_cte  AS ac
JOIN before_cte AS be ON ac.platform = be.platform
ORDER BY growth_rate;

-- Results: Retail -2.43% | Shopify +7.18%
-- Insight: Customers shifting from physical Retail to online Shopify
--          Invest in Shopify — it is the growth engine

-- Dimension 3: Age Band
WITH before_cte AS (
    SELECT age_band, SUM(sales) AS before_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-03-23' AND week_date < '2020-06-15'
    GROUP BY age_band
),
after_cte AS (
    SELECT age_band, SUM(sales) AS after_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-06-15' AND week_date < '2020-09-07'
    GROUP BY age_band
)
SELECT
    '12 Week Window'                                                         AS window_type,
    ac.age_band,
    be.before_sales,
    ac.after_sales,
    ac.after_sales - be.before_sales                                         AS actual_growth,
    ROUND(((ac.after_sales - be.before_sales) / be.before_sales) * 100, 2)  AS growth_rate
FROM after_cte  AS ac
JOIN before_cte AS be ON ac.age_band = be.age_band
ORDER BY growth_rate;

-- Results: Unknown -3.34% | Middle Aged -1.97% | Young Adults -0.92%
-- Insight: Young Adults least affected — environmentally conscious generation
--          Unknown dominates — critical data collection gap

-- Dimension 4: Demographic
WITH before_cte AS (
    SELECT demographic, SUM(sales) AS before_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-03-23' AND week_date < '2020-06-15'
    GROUP BY demographic
),
after_cte AS (
    SELECT demographic, SUM(sales) AS after_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-06-15' AND week_date < '2020-09-07'
    GROUP BY demographic
)
SELECT
    '12 Week Window'                                                         AS window_type,
    ac.demographic,
    be.before_sales,
    ac.after_sales,
    ac.after_sales - be.before_sales                                         AS actual_growth,
    ROUND(((ac.after_sales - be.before_sales) / be.before_sales) * 100, 2)  AS growth_rate
FROM after_cte  AS ac
JOIN before_cte AS be ON ac.demographic = be.demographic
ORDER BY growth_rate;

-- Results: Unknown -3.34% | Families -1.82% | Couples -0.87%
-- Insight: Families shop in bulk at Retail — most affected by packaging change
--          Couples more resilient — smaller purchases, mix of channels

-- Dimension 5: Customer Type
WITH before_cte AS (
    SELECT customer_type, SUM(sales) AS before_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-03-23' AND week_date < '2020-06-15'
    GROUP BY customer_type
),
after_cte AS (
    SELECT customer_type, SUM(sales) AS after_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-06-15' AND week_date < '2020-09-07'
    GROUP BY customer_type
)
SELECT
    '12 Week Window'                                                         AS window_type,
    ac.customer_type,
    be.before_sales,
    ac.after_sales,
    ac.after_sales - be.before_sales                                         AS actual_growth,
    ROUND(((ac.after_sales - be.before_sales) / be.before_sales) * 100, 2)  AS growth_rate
FROM after_cte  AS ac
JOIN before_cte AS be ON ac.customer_type = be.customer_type
ORDER BY growth_rate;

-- Results: Guest -3.00% | Existing -2.27% | New +1.01%
-- Insight: Guest customers have no loyalty — easiest to lose after a change
--          New customers never knew old packaging — no negative comparison

-- ============================================================
-- BONUS: Recommendations for Danny
-- ============================================================
-- 1. FIX UNKNOWN DATA → Unknown caused -3.34% across age_band AND demographic
--    Action: Audit data pipeline, improve collection at point of sale,
--            add more categories (Singles, Business) beyond Couples/Families
--
-- 2. RETAIL DECLINE → Retail dropped -2.43% — largest absolute loss
--    Action: Launch marketing campaign explaining packaging change does NOT
--            affect product quality. Consider dual-use packaging designs.
--
-- 3. INVEST IN SHOPIFY → Shopify grew +7.18% — the growth engine
--    Action: Enhance UI, launch new products online first, target
--            Young Adults and New customers who embrace change
--
-- 4. CONVERT GUESTS TO MEMBERS → Guests dropped -3.00%
--    Action: Offer loyalty discounts and incentives to convert
--            guest into registered members before they leave
--
-- 5. REGIONAL STRATEGY → Asia -3.26%, Oceania -3.03%
--    Action: Study Europe's +4.73% success — replicate in declining regions
--            Launch regional awareness campaigns on sustainable packaging
-- ============================================================
