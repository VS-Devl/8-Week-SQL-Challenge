-- ============================================================
-- SECTION C: PRODUCT ANALYSIS
-- ============================================================

-- 1: What are the top 3 products by total revenue before discount?
SELECT 
    pd.product_name, 
    SUM(s.qty * s.price) AS total_revenue
FROM sales AS s
JOIN product_details AS pd ON s.prod_id = pd.product_id
GROUP BY pd.product_name
ORDER BY 2 DESC 
LIMIT 3;
-- Result: Blue Polo Shirt - Mens | Grey Fashion Jacket - Womens | White Tee Shirt - Mens

-- 2: What is the total quantity, revenue and discount for each segment?
SELECT 
    pd.segment_name, 
    SUM(s.qty)                                          AS total_quantity, 
    SUM(s.qty * s.price)                                AS revenue, 
    ROUND(SUM(s.qty * s.price * s.discount / 100), 2)  AS total_discount
FROM sales AS s
JOIN product_details AS pd ON s.prod_id = pd.product_id
GROUP BY pd.segment_name;

-- 3: What is the top selling product for each segment?
-- Ranked by total quantity sold — top selling = most units moved
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
SELECT segment_name, product_name, total_quantity
FROM rank_cte
WHERE row_num = 1;

-- 4: What is the total quantity, revenue and discount for each category?
SELECT 
    pd.category_name, 
    SUM(s.qty)                                          AS total_quantity, 
    SUM(s.qty * s.price)                                AS revenue, 
    ROUND(SUM(s.qty * s.price * s.discount / 100), 2)  AS discount
FROM sales AS s
JOIN product_details AS pd ON s.prod_id = pd.product_id
GROUP BY pd.category_name;

-- 5: What is the top selling product for each category?
-- Ranked by total quantity sold
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
SELECT category_name, product_name, total_quantity
FROM rank_cte
WHERE row_num = 1;


-- 6: What is the percentage split of revenue by product for each segment?
-- SUM() OVER(PARTITION BY segment_name) gives segment total as denominator
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


-- 7: What is the percentage split of revenue by segment for each category?
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

-- 8: What is the percentage split of total revenue by category?
-- SUM() OVER() without PARTITION BY gives grand total as denominator
WITH product_cte AS (
    SELECT pd.category_name, SUM(s.qty * s.price) AS revenue
    FROM sales AS s
    JOIN product_details AS pd ON s.prod_id = pd.product_id
    GROUP BY pd.category_name
)
SELECT *, 
    ROUND(revenue / SUM(revenue) OVER() * 100, 2) AS percent_by_revenue
FROM product_cte;

-- 9: What is the total transaction penetration for each product?
-- Penetration = % of unique transactions containing at least 1 unit of a specific product
-- Always COUNT(DISTINCT txn_id) — never COUNT rows
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
