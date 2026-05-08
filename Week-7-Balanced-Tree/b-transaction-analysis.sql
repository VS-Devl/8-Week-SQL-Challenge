-- ============================================================
-- SECTION B: TRANSACTION ANALYSIS
-- ============================================================

-- 1: How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS unique_transactions 
FROM sales;
-- Result: 2500 unique transactions — matches profiling numbers
