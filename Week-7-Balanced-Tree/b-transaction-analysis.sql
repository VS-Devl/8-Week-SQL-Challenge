-- ============================================================
-- SECTION B: TRANSACTION ANALYSIS
-- ============================================================

-- 1: How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS unique_transactions 
FROM sales;
-- Result: 2500 unique transactions — matches profiling numbers

-- 2: What is the average unique products purchased in each transaction?
-- Step 1: Count distinct products per transaction in CTE
-- Step 2: Take average of those counts
WITH average_cte AS (
    SELECT txn_id, COUNT(DISTINCT prod_id) AS unique_products
    FROM sales
    GROUP BY txn_id
)
SELECT ROUND(AVG(unique_products), 2) AS avg_unique_products 
FROM average_cte;
-- Result: 6.04 unique products per transaction on average

