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
