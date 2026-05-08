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
-- Result: Blue Polo Shirt - Mens | Grey Fashion Jacket - Womens | White Tee Shirt - Mens

