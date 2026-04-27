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
