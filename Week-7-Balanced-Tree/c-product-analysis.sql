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
