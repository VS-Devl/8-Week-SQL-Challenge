-- Section B: Customer Transactions

-- 1: What is the unique count and total amount for each transaction type?
-- Logic: Grouping by transaction type to see the volume and monetary value of each activity.
SELECT 
    txn_type,
    COUNT(*) AS transaction_count, 
    SUM(txn_amount) AS total_amount 
FROM customer_transactions
GROUP BY txn_type;


-- 2: What is the average total historical deposit counts and amounts for all customers?
-- Logic: Creating a CTE to aggregate deposits per customer first, then averaging those totals.
WITH customer_deposit_summary AS (
    SELECT 
        customer_id,
        COUNT(*) AS deposit_count, 
        SUM(txn_amount) AS total_deposit_amount
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)
SELECT 
    ROUND(AVG(deposit_count), 0) AS avg_deposit_count,  
    ROUND(AVG(total_deposit_amount), 0) AS avg_deposit_amount
FROM customer_deposit_summary;

