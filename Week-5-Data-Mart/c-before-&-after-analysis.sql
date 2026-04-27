-- Section C: Before & After Analysis
-- ============================================================
-- Technique Used: Before & After Analysis (Difference in Differences)
-- Baseline Date : 2020-06-15 (Danny's sustainable packaging change)
-- Rule          : 2020-06-15 is included in the AFTER period as the change happen or start from this date.
-- ============================================================

-- ============================================================
-- Q1: Total sales for 4 weeks before and after 2020-06-15
--     Growth/reduction rate in actual values and percentage of sales.
-- ============================================================
-- Boundary Date Calculation:
--   4 weeks before → DATE_SUB('2020-06-15', INTERVAL 4 WEEK) = 2020-05-18
--   4 weeks after  → DATE_ADD('2020-06-15', INTERVAL 4 WEEK) = 2020-07-13
-- ============================================================

-- Boundary date helpers (for reference)
SELECT DATE_SUB('2020-06-15', INTERVAL 4 WEEK) AS before_date;  -- 2020-05-18
SELECT DATE_ADD('2020-06-15', INTERVAL 4 WEEK) AS after_date;   -- 2020-07-13

WITH before_cte AS (
    SELECT SUM(sales) AS before_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-05-18'     -- 4 weeks before baseline
      AND week_date <  '2020-06-15'     -- exclude baseline (belongs to AFTER)
),
after_cte AS (
    SELECT SUM(sales) AS after_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-06-15'     -- baseline included in AFTER period
      AND week_date <  '2020-07-13'     -- 4 weeks after (< not <= = exactly 4 weeks)
)
SELECT
    be.before_sales,
    af.after_sales,
    af.after_sales - be.before_sales                                    AS growth_rate_actual,
    ROUND(((af.after_sales - be.before_sales) / be.before_sales) * 100, 2) AS growth_rate_percent
FROM after_cte  AS af
CROSS JOIN before_cte AS be;

-- Result  : -26,884,188 actual | -1.15% rate
-- Insight : Small but clear reduction immediately after packaging change
-- Note    : CROSS JOIN used because both CTEs return a single row —
--           no matching key needed, result is one combined row.


-- ============================================================
-- Q2: Total sales for 12 weeks before and after 2020-06-15
--     Growth/reduction rate in actual values and percentage
-- ============================================================
-- Boundary Date Calculation:
--   12 weeks before → DATE_SUB('2020-06-15', INTERVAL 12 WEEK) = 2020-03-23
--   12 weeks after  → DATE_ADD('2020-06-15', INTERVAL 12 WEEK) = 2020-09-07
-- Why 12 weeks? Some impacts take time to appear in the market.
-- Short windows catch immediate shock. Long windows reveal sustained impact.
-- ============================================================

-- Boundary date helpers (for reference)
SELECT DATE_SUB('2020-06-15', INTERVAL 12 WEEK) AS before_date;  -- 2020-03-23
SELECT DATE_ADD('2020-06-15', INTERVAL 12 WEEK) AS after_date;   -- 2020-09-07

WITH before_cte AS (
    SELECT SUM(sales) AS before_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-03-23'     -- 12 weeks before baseline
      AND week_date <  '2020-06-15'     -- exclude baseline
),
after_cte AS (
    SELECT SUM(sales) AS after_sales
    FROM weekly_sales_final
    WHERE week_date >= '2020-06-15'     -- baseline included in AFTER
      AND week_date <  '2020-09-07'     -- 12 weeks after
)
SELECT
    be.before_sales,
    af.after_sales,
    af.after_sales - be.before_sales                                    AS growth_rate_actual,
    ROUND(((af.after_sales - be.before_sales) / be.before_sales) * 100, 2) AS growth_rate_percent
FROM after_cte  AS af
CROSS JOIN before_cte AS be;

-- Result  : -152,325,394 actual | -2.14% rate
-- Insight : Damage nearly 6x larger over 12 weeks vs 4 weeks
--           Impact is sustained and growing — not a temporary shock
-- Key Lesson: Always use multiple time windows for complete picture


-- ============================================================
-- Q3: Compare 4-week and 12-week periods with 2018 and 2019
--     to determine if packaging change caused the 2020 decline
-- ============================================================
-- Why week_number instead of exact dates?
--   '2019-06-15' falls on a Saturday — not in dataset (Mondays only)
--   Week 24 exists in ALL years at the same relative position
--   Week numbers are year-agnostic, exact dates are day-dependent
-- Baseline: 2020-06-15 = Week 24
--   4 week window  → weeks 20-23 (before) | weeks 24-27 (after)
--   12 week window → weeks 12-23 (before) | weeks 24-35 (after)
-- ============================================================

-- 4 Week Window — All Years
WITH before_cte AS (
    SELECT
        calender_year,
        SUM(sales) AS before_sales
    FROM weekly_sales_final
    WHERE week_number >= 20
      AND week_number <  24
    GROUP BY calender_year
),
after_cte AS (
    SELECT
        calender_year,
        SUM(sales) AS after_sales
    FROM weekly_sales_final
    WHERE week_number >= 24
      AND week_number <  28
    GROUP BY calender_year
)
SELECT
    '4 Week Window' AS window_type,
    ac.calender_year,
    be.before_sales,
    ac.after_sales,
    ac.after_sales - be.before_sales                                         AS actual_growth,
    ROUND(((ac.after_sales - be.before_sales) / be.before_sales) * 100, 2)  AS growth_rate
FROM after_cte  AS ac
JOIN before_cte AS be ON ac.calender_year = be.calender_year
ORDER BY ac.calender_year;

-- 4 Week Results:
-- 2018 → +0.19% (growth)
-- 2019 → +0.10% (growth)
-- 2020 → -1.15% (reduction) ← clear anomaly

-- 12 Week Window — All Years
WITH before_cte AS (
    SELECT
        calender_year,
        SUM(sales) AS before_sales
    FROM weekly_sales_final
    WHERE week_number >= 12
      AND week_number <  24
    GROUP BY calender_year
),
after_cte AS (
    SELECT
        calender_year,
        SUM(sales) AS after_sales
    FROM weekly_sales_final
    WHERE week_number >= 24
      AND week_number <  36
    GROUP BY calender_year
)
SELECT
    '12 Week Window' AS window_type,
    ac.calender_year,
    be.before_sales,
    ac.after_sales,
    ac.after_sales - be.before_sales                                         AS actual_growth,
    ROUND(((ac.after_sales - be.before_sales) / be.before_sales) * 100, 2)  AS growth_rate
FROM after_cte  AS ac
JOIN before_cte AS be ON ac.calender_year = be.calender_year
ORDER BY ac.calender_year;

-- 12 Week Results:
-- 2018 → +1.63% (strong growth)
-- 2019 → -0.30% (slight decline — warning sign already present)
-- 2020 → -2.14% (significant reduction) ← packaging change impact confirmed
-- Key Insight: Business was already showing signs of slowdown in 2019
--              Packaging change accelerated the decline but is not sole cause
