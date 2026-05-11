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
