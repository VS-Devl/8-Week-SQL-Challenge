-- ============================================================
-- SECTION C: SEGMENT LEVEL ANALYSIS
-- ============================================================


-- 1: Top 10 and Bottom 10 interests with largest composition values
--     Only using maximum composition per interest with corresponding month_year
-- -------------------------------------------------------
-- Step 1: Find max composition per interest across all months
-- Step 2: Join back to interest_metrics to get corresponding month_year
-- Step 3: Join interest_map for interest name

WITH max_cte AS (
    SELECT 
        interest_id, 
        MAX(composition) AS maximum
    FROM interest_metrics
    GROUP BY interest_id
)
SELECT 
    imt.month_year, 
    imp.interest_name, 
    mac.maximum
FROM max_cte AS mac
JOIN interest_metrics AS imt 
    ON mac.interest_id = imt.interest_id 
    AND mac.maximum = imt.composition
JOIN interest_map AS imp 
    ON mac.interest_id = imp.id
ORDER BY mac.maximum DESC 
LIMIT 10;
-- Change ORDER BY to ASC LIMIT 10 for bottom 10

-- 2: Which 5 interests had the lowest average ranking value?
SELECT 
    imp.interest_name, 
    ROUND(AVG(imt.ranking), 2) AS average_rank
FROM interest_metrics AS imt
JOIN interest_map AS imp ON imt.interest_id = imp.id
GROUP BY imp.interest_name
ORDER BY average_rank ASC 
LIMIT 5;
-- Result: Winter Apparel Shoppers ranks 1st with perfect average rank of 1.00

-- 3: Which 5 interests had the largest standard deviation in percentile_ranking?
-- Standard deviation measures how widely spread the values are from the mean
-- High stddev = volatile interest — sometimes very high, sometimes very low ranking
SELECT 
    imp.interest_name, 
    ROUND(STDDEV_SAMP(imt.percentile_ranking), 2) AS st_dev
FROM interest_metrics AS imt
JOIN interest_map AS imp ON imt.interest_id = imp.id
GROUP BY imp.interest_name
ORDER BY st_dev DESC 
LIMIT 5;
-- Result: Techies (30.18), Entertainment Industry Decision Makers (28.97)
-- These are volatile interests — seasonal or event-driven spikes


-- 4: For the 5 interests from C3 — minimum and maximum percentile_ranking
--     with corresponding month_year for each
-- -------------------------------------------------------
-- Step 1: Get top 5 interests by standard deviation
-- Step 2: Find max and min percentile_ranking per interest
-- Step 3: Double join back to interest_metrics to get corresponding month_year
--         for both maximum and minimum values

WITH std_cte AS (
    SELECT 
        imt.interest_id, 
        ROUND(STDDEV_SAMP(imt.percentile_ranking), 2) AS st_dev
    FROM interest_metrics AS imt
    JOIN interest_map AS imp ON imt.interest_id = imp.id
    GROUP BY imt.interest_id
    ORDER BY st_dev DESC 
    LIMIT 5
),
rank_cte AS (
    SELECT 
        sc.interest_id, 
        MAX(imt.percentile_ranking) AS maximum, 
        MIN(imt.percentile_ranking) AS minimum
    FROM std_cte AS sc
    JOIN interest_metrics AS imt ON sc.interest_id = imt.interest_id
    GROUP BY sc.interest_id
)
SELECT 
    rc.interest_id, 
    imp.interest_name, 
    imt.month_year   AS max_month_year,
    rc.maximum, 
    imt2.month_year  AS min_month_year,
    rc.minimum
FROM rank_cte AS rc
JOIN interest_metrics AS imt  
    ON rc.interest_id = imt.interest_id 
    AND rc.maximum = imt.percentile_ranking
JOIN interest_metrics AS imt2 
    ON rc.interest_id = imt2.interest_id 
    AND rc.minimum = imt2.percentile_ranking
JOIN interest_map AS imp ON rc.interest_id = imp.id;
-- These interests show dramatic drops in ranking — classic seasonal trend pattern
-- Tampa Trip Planners: 75.03 (Jul 2018) → 4.84 (Mar 2019) — summer travel season
-- Personalized Gift Shoppers: 73.15 (Mar 2019) → 5.70 (Jun 2019) — event driven

-- 5: Customer segment description based on composition and ranking values
-- -------------------------------------------------------
/*
SEGMENT ANALYSIS SUMMARY

By analyzing the segments of customers, we have decided that these customers 
are following trends. For example, a special event, holidays for a trip or picnic, 
and entertainment decision-makers, like if a movie or show is coming, it starts 
gaining hype, as was noted in our standard deviation question too.

From our analysis and data, this shows that we have to track these trends if they 
keep recurring over time, like summer holidays and specific events like Eid and 
Eid ul-Adha. If Eid ul-Adha is approaching, we should create interest in buying 
an animal for customers, and this will only work before Eid ul-Adha — after this, 
there is no way people will show interest in it.

WHAT TO SHOW: Seasonal and event-driven products at the right time —
travel packages before summer, gifts before special occasions, 
winter apparel before cold season.

WHAT TO AVOID: Showing off-trend products during inactive periods —
trip planner ads when there are no upcoming holidays, gift promotions 
when no events are approaching, winter apparel during summer.

Key insight: Timing is everything for these customer segments.
Right product. Right time. Right customer.
*/
