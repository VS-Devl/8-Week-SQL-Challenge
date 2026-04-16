-- DATA PROFILING TABLE 1: customer_nodes
-- Goal: Identify anomalies, placeholders, and data distribution prior to ELT(Extract, Transform/ Load).

-- 1: CHECKING FOR EXACT DUPLICATES
-- Using ROW_NUMBER() allows us to identify if the same event was ingested twice.
-- Insight: Partitioning by all columns ensures we catch 'hard' duplicates.
with row_cte as(
	select *, ROW_NUMBER() over(PARTITION BY customer_id, region_id, node_id, start_date, end_date) as row_num
	from customer_nodes
)
select * from row_cte
where row_num > 1;  
-- Result: No duplicates. This confirms the data ingestion process is stable.

-- 2: NULL / BLANK / EMPTY STRING AUDIT 
-- Checking for missing identifiers that would break JOINs or aggregations.
select 	
	  sum(case when customer_id is null then 1 else 0 end) as customer_nulls,
    sum(case when region_id is null then 1 else 0 end) as region_nulls,
    sum(case when node_id is null then 1 else 0 end) as node_nulls,
    sum(case when start_date is null then 1 else 0 end) as start_date_nulls,
    sum(case when end_date is null then 1 else 0 end) as end_date_nulls
from customer_nodes; 
-- Result: No nulls found.

select * from customer_nodes
where customer_id in (NULL, ' ');
-- (Note: In a pipeline, we'd also check region_id and node_id here).

-- 3: TEMPORAL BOUNDARY & PLACEHOLDER CHECK
-- Looking for outliers in time. 
select max(start_date), min(start_date), max(end_date), min(end_date) from customer_nodes;  
-- Finding: '9999-12-31' detected. 
-- Insight: This is a 'High Date' or 'Sentinel Value' representing currently active nodes. 
-- It prevents NULLs in the end_date column but requires special handling in DATEDIFF calculations.

select distinct end_date from customer_nodes ORDER BY end_date desc;  
select count(*) from customer_nodes
where end_date = '9999-12-31';  
-- Result: 500 records are currently 'Live'.

-- 4: GRANULARITY & SCALE CHECK
-- Determining the size of the dataset and the customer base.
select count(*), count(distinct customer_id) from customer_nodes; 
-- Findings: 3,500 total records for 500 unique customers. 
-- Meaning: On average, each customer has moved between 7 different nodes/regions.

-- 5: LOGICAL DATE CONTRADICTIONS
-- Validating chronological integrity.
select * from customer_nodes
where start_date > end_date;  
-- Result: All time flows forward. Logical integrity is 100%.

-- 6: CATEGORICAL DISTRIBUTION
-- Checking the range of categorical IDs.
select distinct region_id from customer_nodes;
select distinct node_id from customer_nodes;
-- Result: 5 unique regions and 5 unique nodes. 
-- Note: This confirms our 'Lookup Tables' (like the regions table) should have exactly 5 entries.

-- 7: DATA TYPE & SCHEMA VALIDATION
-- METHOD 1: THE QUICK VIEW (MySQL)
DESCRIBE customer_nodes; -- Your Table Name

-- METHOD 2: THE DETAILED VIEW (Information Schema).
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH, 
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customer_nodes';
