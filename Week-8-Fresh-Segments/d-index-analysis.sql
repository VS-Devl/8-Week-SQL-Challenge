-- ================================================================================
-- SECTION D (INDEX ANALYSIS)
-- ================================================================================

-- Before starting the questions, Danny asked to create a new column: average_composition.
-- We cannot simply add a static column because this is time-series data where values 
-- fluctuate. We have two options:
-- 1. Create a temporary column using a CTE when needed.
-- 2. Generate an auto-updating column that reflects value changes.

ALTER TABLE interest_metrics
ADD COLUMN average_composition DECIMAL(10,2)
GENERATED ALWAYS AS (ROUND(composition / index_value, 2)) STORED;

/* EXPLANATION OF 'STORED' GENERATED COLUMNS:
Basically, there are two types of generated columns: Virtual and Stored.

- Virtual: Computes values from scratch every time you query them. 
  This takes time but uses no storage. Best for small datasets.
- Stored: Pre-calculates and stores the values on disk. 
  In massive datasets (billions of rows), this is significantly more efficient 
  because it saves CPU time by retrieving stored values instead of re-calculating.
*/

-- -----------------------------------------------------------------------------
-- 1: What is the top 10 interests by the average composition for each month?
-- -----------------------------------------------------------------------------
WITH rank_cte AS (
    SELECT 
        *, 
        DENSE_RANK() OVER(PARTITION BY month_year ORDER BY average_composition DESC) AS rnk_int
    FROM interest_metrics
)
SELECT 
    interest_id, 
    interest_name, 
    month_year, 
    average_composition, 
    rnk_int
FROM rank_cte AS rc
JOIN interest_map AS imp ON rc.interest_id = imp.id
WHERE rnk_int BETWEEN 1 AND 10
ORDER BY month_year, rnk_int;

-- -----------------------------------------------------------------------------
-- 2: For all of these top 10 interests - which interest appears the most often?
-- -----------------------------------------------------------------------------
WITH rank_cte AS (
    SELECT 
        *, 
        DENSE_RANK() OVER(PARTITION BY month_year ORDER BY average_composition DESC) AS rnk_int
    FROM interest_metrics
),
interest_cte AS (
    SELECT 
        interest_id, 
        interest_name, 
        month_year, 
        average_composition, 
        rnk_int
    FROM rank_cte AS rc
    JOIN interest_map AS imp ON rc.interest_id = imp.id
    WHERE rnk_int BETWEEN 1 AND 10
)
SELECT 
    interest_id, 
    COUNT(*) AS total_appear
FROM interest_cte
GROUP BY interest_id
ORDER BY total_appear DESC;

-- -----------------------------------------------------------------------------
-- 3: What is the average of the average composition for the top 10 interests for each month?
-- -----------------------------------------------------------------------------
WITH rank_cte AS (
    SELECT 
        *, 
        DENSE_RANK() OVER(PARTITION BY month_year ORDER BY average_composition DESC) AS rnk_int
    FROM interest_metrics
),
interest_cte AS (
    SELECT 
        interest_id, 
        interest_name, 
        month_year, 
        average_composition, 
        rnk_int
    FROM rank_cte AS rc
    JOIN interest_map AS imp ON rc.interest_id = imp.id
    WHERE rnk_int BETWEEN 1 AND 10
)
SELECT 
    month_year, 
    ROUND(AVG(average_composition), 2) AS avg_value
FROM interest_cte
GROUP BY month_year
ORDER BY month_year;

