-- ============================================================
-- MONTHLY REPORT — BALANCED TREE CLOTHING CO.
-- Stored Procedure covering Section A, B and C
-- ============================================================
/*
REPORTING CHALLENGE — BALANCED TREE CLOTHING CO.

This reporting challenge required building a single SQL script containing all analysis
from Section A, B and C so that the Balanced Tree team can run it every month with one call.

To achieve this, a stored procedure called monthly_report() was created, wrapping all
queries inside a single BEGIN...END block. This eliminates the need to run queries
individually each month and ensures consistent, automated reporting.

Key engineering decisions made:
- Section A: All 3 metrics combined into a single SELECT as they share the same grain and source.
- Section C Q2 and Q4: Combined using UNION ALL since both questions share identical
  columns — only the grouping level differs (category vs segment). A label column was
  added to distinguish the two levels in the output.
- All remaining questions kept as separate queries due to different grains, CTEs and joins.

Danny mentioned that multiple tables can be used freely — however, by identifying
shared grains across questions, unnecessary duplication was avoided.
*/
-- ============================================================

DELIMITER $$

CREATE PROCEDURE monthly_report()
BEGIN

-- ============================================================
-- SECTION A: HIGH LEVEL SALES ANALYSIS
-- ============================================================

-- A1/A2/A3
SELECT 
    SUM(qty)                                    AS total_items_sold, 
    SUM(qty * price)                            AS total_revenue, 
    ROUND(SUM(qty * price * discount / 100), 2) AS total_discount
FROM sales;


-- ============================================================
-- SECTION B: TRANSACTION ANALYSIS
-- ============================================================

-- B1: How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS unique_transactions 
FROM sales;  		

-- B2: What is the average unique products purchased in each transaction?
WITH average_cte AS (
    SELECT txn_id, COUNT(DISTINCT prod_id) AS unique_products
    FROM sales
    GROUP BY txn_id
)
SELECT 
    'each transaction'              AS col_name,
    ROUND(AVG(unique_products), 2)  AS avg_unique_products 
FROM average_cte;

-- B3: What are the 25th, 50th and 75th percentile values for the revenue per transaction?
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
    'revenue'                                           AS percentile_rank_value,
    MAX(CASE WHEN pr_rank <= 0.25 THEN revenue END)    AS `25th_percentile`,
    MAX(CASE WHEN pr_rank <= 0.50 THEN revenue END)    AS `50th_percentile`,
    MAX(CASE WHEN pr_rank <= 0.75 THEN revenue END)    AS `75th_percentile`
FROM rank_cte;

-- B4: What is the average discount value per transaction?
WITH average_cte AS (
    SELECT txn_id, ROUND(SUM(qty * price * discount / 100), 2) AS discounted_amount 
    FROM sales
    GROUP BY txn_id
)
SELECT 
    'per transaction'                   AS col_name,
    ROUND(AVG(discounted_amount), 2)    AS avg_discount_value
FROM average_cte;

-- B5: What is the percentage split of all transactions for members vs non-members?
WITH percent_cte AS (
    SELECT member, COUNT(DISTINCT txn_id) AS unique_transaction
    FROM sales
    GROUP BY member
)
SELECT 
    member, 
    unique_transaction,
    ROUND(unique_transaction / (SELECT COUNT(DISTINCT txn_id) FROM sales) * 100, 2) AS percent_split
FROM percent_cte;

-- B6: What is the average revenue for member transactions and non-member transactions?
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


-- ============================================================
-- SECTION C: PRODUCT ANALYSIS
-- ============================================================

-- C1: What are the top 3 products by total revenue before discount?
SELECT 
    pd.product_name, 
    SUM(s.qty * s.price) AS total_revenue
FROM sales AS s
JOIN product_details AS pd ON s.prod_id = pd.product_id
GROUP BY pd.product_name
ORDER BY 2 DESC 
LIMIT 3;

-- C2 & C4: Total quantity, revenue and discount for each segment and category
SELECT 
    'category'                                          AS level,
    pd.category_name                                    AS name,
    SUM(s.qty)                                          AS total_quantity, 
    SUM(s.qty * s.price)                                AS revenue, 
    ROUND(SUM(s.qty * s.price * s.discount / 100), 2)  AS discount
FROM sales AS s
JOIN product_details AS pd ON s.prod_id = pd.product_id
GROUP BY pd.category_name

UNION ALL

SELECT 
    'segment'                                           AS level,
    pd.segment_name                                     AS name,
    SUM(s.qty)                                          AS total_quantity, 
    SUM(s.qty * s.price)                                AS revenue, 
    ROUND(SUM(s.qty * s.price * s.discount / 100), 2)  AS discount
FROM sales AS s
JOIN product_details AS pd ON s.prod_id = pd.product_id
GROUP BY pd.segment_name;

-- C3: What is the top selling product for each segment?
WITH products_cte AS (
    SELECT pd.segment_name, pd.product_name, SUM(s.qty) AS total_quantity
    FROM sales AS s
    JOIN product_details AS pd ON s.prod_id = pd.product_id
    GROUP BY pd.segment_name, pd.product_name
),
rank_cte AS (
    SELECT segment_name, product_name, total_quantity,
           ROW_NUMBER() OVER(PARTITION BY segment_name ORDER BY total_quantity DESC) AS row_num
    FROM products_cte
)
SELECT segment_name, product_name, total_quantity AS top_selling_quantity
FROM rank_cte
WHERE row_num = 1;

-- C5: What is the top selling product for each category?
WITH product_cte AS (
    SELECT pd.category_name, pd.product_name, SUM(s.qty) AS total_quantity
    FROM sales AS s
    JOIN product_details AS pd ON s.prod_id = pd.product_id
    GROUP BY 1, 2
),
rank_cte AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY category_name ORDER BY total_quantity DESC) AS row_num
    FROM product_cte
)
SELECT category_name, product_name, total_quantity AS top_selling_quantity
FROM rank_cte
WHERE row_num = 1;

-- C6: What is the percentage split of revenue by product for each segment?
WITH product_cte AS (
    SELECT pd.segment_name, pd.product_name, SUM(s.qty * s.price) AS revenue
    FROM sales AS s
    JOIN product_details AS pd ON s.prod_id = pd.product_id
    GROUP BY 1, 2
)
SELECT 
    segment_name, 
    product_name, 
    ROUND(revenue / SUM(revenue) OVER(PARTITION BY segment_name) * 100, 2) AS percent_by_product
FROM product_cte;

-- C7: What is the percentage split of revenue by segment for each category?
WITH product_cte AS (
    SELECT pd.category_name, pd.segment_name, SUM(s.qty * s.price) AS revenue
    FROM sales AS s
    JOIN product_details AS pd ON s.prod_id = pd.product_id
    GROUP BY 1, 2
)
SELECT 
    category_name, 
    segment_name, 
    ROUND(revenue / SUM(revenue) OVER(PARTITION BY category_name) * 100, 2) AS percent_by_segment
FROM product_cte;

-- C8: What is the percentage split of total revenue by category?
WITH product_cte AS (
    SELECT pd.category_name, SUM(s.qty * s.price) AS revenue
    FROM sales AS s
    JOIN product_details AS pd ON s.prod_id = pd.product_id
    GROUP BY pd.category_name
)
SELECT *, 
    ROUND(revenue / SUM(revenue) OVER() * 100, 2) AS percent_by_revenue
FROM product_cte;

-- C9: What is the total transaction penetration for each product?
WITH product_cte AS (
    SELECT pd.product_name, COUNT(DISTINCT txn_id) AS transactions
    FROM sales AS s
    JOIN product_details AS pd ON s.prod_id = pd.product_id
    GROUP BY pd.product_name
)
SELECT 
    product_name, 
    ROUND(transactions / (SELECT COUNT(DISTINCT txn_id) FROM sales) * 100, 2) AS penetration_rate
FROM product_cte;

-- C10: What is the most common combination of any 3 products in a single transaction?
WITH product_cte AS (
    SELECT s1.prod_id AS id1, s2.prod_id AS id2, s3.prod_id AS id3, COUNT(*) AS total
    FROM sales AS s1
    JOIN sales AS s2 ON s1.txn_id = s2.txn_id
    JOIN sales AS s3 ON s2.txn_id = s3.txn_id
    WHERE s1.prod_id < s2.prod_id AND s2.prod_id < s3.prod_id
    GROUP BY 1, 2, 3
)
SELECT 
    pd1.product_name, 
    pd2.product_name, 
    pd3.product_name, 
    total AS most_common_combination
FROM product_cte AS pct
JOIN product_details AS pd1 ON pct.id1 = pd1.product_id
JOIN product_details AS pd2 ON pct.id2 = pd2.product_id
JOIN product_details AS pd3 ON pct.id3 = pd3.product_id
ORDER BY total DESC 
LIMIT 3;

END $$

DELIMITER ;

-- ============================================================
-- RUN THE REPORT
-- ============================================================
CALL monthly_report;      -- no parantheses required in MySql
