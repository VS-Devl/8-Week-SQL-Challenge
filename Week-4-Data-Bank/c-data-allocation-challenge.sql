-- SECTION C: Data Allocation Challenge

-- Business Context:
-- Data Bank allocates cloud storage to customers based on their account balance.
-- Three allocation options are tested to estimate monthly storage requirements.
-- ============================================

WITH amounts_cte AS (
    -- Step 1: Assign signed values to each transaction
    -- Deposits are positive (+), purchases and withdrawals are negative (-)
    -- This allows us to calculate running balance using a simple SUM
    SELECT 
        customer_id, 
        txn_date,
        txn_type, 
        CASE WHEN txn_type = 'deposit' 
             THEN txn_amount 
             ELSE -txn_amount 
        END AS signed_amount
    FROM customer_transactions
),

running_amount AS (
    -- Step 2: Calculate running balance per customer ordered by date
    -- SUM() OVER() with ORDER BY creates a cumulative running total
    -- Each row shows the balance AFTER that specific transaction
    SELECT *, 
        SUM(signed_amount) OVER(
            PARTITION BY customer_id 
            ORDER BY txn_date
        ) AS running_balance
    FROM amounts_cte
),

aggreg_amount AS (
    -- Step 3: Calculate min, max and average running balance per customer
    -- Used for Option 2: average amount kept in account
    SELECT 
        customer_id, 
        ROUND(MAX(running_balance), 0) AS max_value, 
        ROUND(MIN(running_balance), 0) AS min_value, 
        ROUND(AVG(running_balance), 0) AS avg_value
    FROM running_amount
    GROUP BY customer_id
),

closing_amounts AS (
    -- Step 4: Calculate closing balance at end of each month per customer
    -- Used for Option 1: balance at end of previous month
    -- COALESCE handles months where a transaction type doesn't exist
    SELECT 
        customer_id, 
        DATE_FORMAT(txn_date, '%Y-%m-01') AS date_month, 
        COALESCE(SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount END), 0) -
        (COALESCE(SUM(CASE WHEN txn_type = 'purchase' THEN txn_amount END), 0) + 
         COALESCE(SUM(CASE WHEN txn_type = 'withdrawal' THEN txn_amount END), 0))
        AS closing_amount
    FROM customer_transactions
    GROUP BY customer_id, date_month
)

-- ============================================
-- OPTION 1: Data allocated based on closing balance at end of each month
-- Negative balances treated as 0 — storage cannot be negative
-- ============================================
-- SELECT 
--     customer_id, 
--     date_month,
--     CASE WHEN closing_amount > 0 THEN closing_amount ELSE 0 END AS data_allocated
-- FROM closing_amounts
-- ORDER BY customer_id;

-- ============================================
-- OPTION 2: Data allocated based on average running balance
-- Negative average balances treated as 0 — storage cannot be negative
-- ============================================
-- SELECT 
--     customer_id,
--     CASE WHEN avg_value > 0 THEN avg_value ELSE 0 END AS data_allocated
-- FROM aggreg_amount;

-- ============================================
-- OPTION 3: Data allocated based on real-time transaction activity
-- Every transaction consumes storage regardless of direction (deposit or spending)
-- ABS() alternative used here with CASE WHEN to demonstrate both approaches
-- ============================================
SELECT 
    customer_id, 
    DATE_FORMAT(txn_date, '%Y-%m-01') AS date_month, 
    SUM(
        CASE WHEN signed_amount < 0 
             THEN -signed_amount 
             ELSE signed_amount 
        END
    ) AS data_allocated
  -- SUM(ABS(signed_amount)) AS data_allocated
FROM amounts_cte
GROUP BY customer_id, date_month
ORDER BY customer_id, date_month;
