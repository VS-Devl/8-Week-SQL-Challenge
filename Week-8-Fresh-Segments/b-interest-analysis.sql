-- ============================================================
-- SECTION B: INTEREST ANALYSIS
-- ============================================================

-- 1: Which interests have been present in all month_year dates in our dataset?
-- Using dynamic subquery to avoid hardcoding the number of months
SELECT 
    imt.interest_id, 
    imp.interest_name,
    COUNT(imt.month_year) AS total_months
FROM interest_metrics AS imt
JOIN interest_map AS imp ON imt.interest_id = imp.id
GROUP BY imt.interest_id, imp.interest_name
HAVING total_months = (SELECT COUNT(DISTINCT month_year) FROM interest_metrics);
-- Result: 480 interests appear in all 14 months

-- 2: Calculate the cumulative percentage of all records starting at 14 months
--     Which total_months value passes the 90% cumulative percentage value?
-- -------------------------------------------------------
-- Step 1: Count months each interest appears in
-- Step 2: Count how many interests share each month count
-- Step 3: Apply cumulative SUM window function ordered from 14 down to 1
WITH records_cte AS (
    SELECT 
        imt.interest_id, 
        imp.interest_name,
        COUNT(imt.month_year) AS month_count
    FROM interest_metrics AS imt
    JOIN interest_map AS imp ON imt.interest_id = imp.id
    GROUP BY imt.interest_id, imp.interest_name
),
total_cte AS (
    SELECT 
        month_count, 
        COUNT(*) AS interest_count
    FROM records_cte
    GROUP BY month_count
)
SELECT 
    month_count,
    interest_count,
    ROUND(SUM(interest_count) OVER(ORDER BY month_count DESC) / 
          SUM(interest_count) OVER() * 100, 4) AS cumulative_percent
FROM total_cte
ORDER BY month_count DESC;
-- Result: At 6 months the cumulative percentage crosses 90% (90.8486%)
-- Interests appearing in fewer than 6 months are considered low quality segments


-- 3: How many total data points would we be removing if we remove all
--     interest_id values with fewer than 6 months?
WITH month_cte AS (
    SELECT interest_id
    FROM interest_metrics
    GROUP BY interest_id
    HAVING COUNT(month_year) < 6
)
SELECT COUNT(*) AS rows_to_remove
FROM interest_metrics
WHERE interest_id IN (SELECT interest_id FROM month_cte);
-- Result: 400 rows to be removed — approximately 3% of total data
