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

-- 3: What are the 25th, 50th and 75th percentile values for the revenue per transaction?
-- Step 1: Calculate revenue per transaction
-- Step 2: Apply PERCENT_RANK() and filter at each percentile boundary using MAX(CASE WHEN)
WITH revenue_cte AS (
    SELECT txn_id, SUM(qty * price) AS revenue
    FROM sales
    GROUP BY txn_id
),
rank_cte AS (
    SELECT *, PERCENT_RANK() OVER(ORDER BY revenue) AS pr_rank
    FROM revenue_cte
)
SELECT 
    MAX(CASE WHEN pr_rank <= 0.25 THEN revenue END) AS `25th_percentile`,
    MAX(CASE WHEN pr_rank <= 0.50 THEN revenue END) AS `50th_percentile`,
    MAX(CASE WHEN pr_rank <= 0.75 THEN revenue END) AS `75th_percentile`
FROM rank_cte;
-- Result: 375 | 509 | 647

-- 4: What is the average discount value per transaction?
-- Step 1: Calculate actual discount amount per transaction (qty * price * discount / 100)
-- Step 2: Take average of those totals
WITH average_cte AS (
    SELECT txn_id, ROUND(SUM(qty * price * discount / 100), 2) AS discounted_amount 
    FROM sales
    GROUP BY txn_id
)
SELECT ROUND(AVG(discounted_amount), 2) AS avg_discount_value
FROM average_cte;
-- Result: 62.49 average discount per transaction

-- 5: What is the percentage split of all transactions for members vs non-members?
-- Using COUNT(DISTINCT txn_id) — grain is transactions not rows
WITH percent_cte AS (
    SELECT member, COUNT(DISTINCT txn_id) AS unique_transactions
    FROM sales
    GROUP BY member
)
SELECT 
    member, 
    unique_transactions,
    ROUND(unique_transactions / (SELECT COUNT(DISTINCT txn_id) FROM sales) * 100, 2) AS percent_split
FROM percent_cte;
-- Result: t = 60.20% | f = 39.80%

-- 6: What is the average revenue for member transactions and non-member transactions?
-- Step 1: Calculate total revenue per transaction with member flag
-- Step 2: Average those totals grouped by member
WITH average_cte AS (
    SELECT txn_id, member, SUM(qty * price) AS revenue
    FROM sales
    GROUP BY txn_id, member
)
SELECT 
    member, 
    ROUND(AVG(revenue), 2) AS avg_revenue
FROM average_cte
GROUP BY member;
-- Result: t = 516.27 | f = 515.04
