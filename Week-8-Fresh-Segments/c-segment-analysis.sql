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
