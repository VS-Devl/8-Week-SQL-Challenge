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
