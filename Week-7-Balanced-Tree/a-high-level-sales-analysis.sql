-- ============================================================
-- SECTION A: HIGH LEVEL SALES ANALYSIS
-- ============================================================

-- 1: What was the total quantity sold for all products?
SELECT SUM(qty) AS total_items_sold 
FROM sales;
-- Result: 45216 items sold in three months
