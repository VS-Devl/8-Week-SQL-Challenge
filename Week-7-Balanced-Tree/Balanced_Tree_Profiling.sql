-- Week 6 — Balanced Tree Clothing Co.
-- Data Profiling & Quality Audit — All 4 Tables
-- ============================================================
-- DATA PROFILING — SALES TABLE
-- ============================================================

-- 1. DATA TYPE AND SCHEMA VALIDATION
describe sales;
select column_name, is_nullable, data_type, character_maximum_length
from information_schema.columns
where table_name = 'sales';

-- 2. DUPLICATE CHECK
with duplicate_cte as(
select *, ROW_NUMBER() over(partition by prod_id, qty, price, discount, member, txn_id, start_txn_time) as row_num
from sales
)
select * from duplicate_cte
where row_num > 1;

-- 3. DATE RANGE CHECK
select min(start_txn_time), max(start_txn_time)
from sales;

-- 4. OUTLIER CHECK — PRICE
select * from sales
where price = 0;		-- no price value with 0
select price from sales
order by price desc;  -- no outlier or high value here

-- 5. CATEGORICAL CHECK
select distinct prod_id from sales;
select distinct member from sales;
select distinct txn_id from sales;

-- 6. GRANULARITY CHECK
select count(distinct prod_id) from sales;  		-- total 12 unique products in the sales table
select count(distinct member) from sales;			-- 2 unique category of member as specified in datatype enum('t','f')
select count(distinct txn_id), count(*) as total from sales;	-- 2500 unique txn_ids and total 15095 rows in the sales table

-- 7. NULL / BLANK VALUES CHECK
select 
	sum(case when prod_id is null or prod_id = '' then 1 else 0 end) as prod_null,
    sum(case when qty is null or qty = '' then 1 else 0 end) as qty_null,
    sum(case when price is null or price = '' then 1 else 0 end) as price_null,
    sum(case when discount is null or discount = '' then 1 else 0 end) as discount_null, -- found 491 values in discount while checking null/blank values
    sum(case when member is null or member = '' then 1 else 0 end) as member_null,
    sum(case when txn_id is null or txn_id = '' then 1 else 0 end) as txn_null
from sales;

select count(discount) from sales
where discount = 0;		-- the values were 0 where the product have no discount

/*
PROFILING SUMMARY — SALES TABLE
While performing data profiling on the sales table, here is what was found:
- The dataset contains 12 unique prod_ids, 2500 unique txn_ids and 15095 total rows.
- No duplicates found in the sales table.
- Data types are correctly defined.
- No NULL or blank values found in any column.
- 491 rows have discount = 0 which is valid business data — discount can be zero.
- Date range is clean from 2021-01-01 to 2021-03-30. No sentinel values like '9999-12-31'.
- No outlier or zero values found in the price column.
*/

-- ============================================================
-- DATA PROFILING — PRODUCT_DETAILS TABLE
-- ============================================================

-- 1. DATA TYPE AND SCHEMA VALIDATION
DESCRIBE product_details;
select column_name, data_type, character_maximum_length, is_nullable
from information_schema.columns
where table_name = 'product_details';


-- 2. DUPLICATE CHECK
with duplicate_cte as(
select *, ROW_NUMBER() OVER(PARTITION BY product_id, price, product_name, category_id, segment_id, style_id, category_name, segment_name, style_name) as row_num
from product_details
)
select * from duplicate_cte
where row_num > 1;


-- 3. CATEGORICAL CHECK
select distinct product_name from product_details;
select distinct category_name from product_details;
select distinct segment_name from product_details;
select distinct style_name from product_details;


-- 4. GRANULARITY CHECK
select count(distinct product_name) from product_details;  -- 12 unique products, matching sales table
select count(distinct category_name) from product_details; -- 2 unique categories (Mens, Womens)
select count(distinct segment_name) from product_details;  -- 4 unique segments
select count(distinct style_name) from product_details;    -- 12 unique style names matching product count


-- 5. OUTLIER CHECK — PRICE
select price from product_details order by price desc;
select price from product_details order by price asc;
-- no zero values, no outliers, no data errors in price column


-- 6. NULL / BLANK VALUES CHECK
select 
	sum(case when product_id is null or product_id = '' then 1 else 0 end) as product_null,
    sum(case when price is null or price = '' then 1 else 0 end) as price_null,
    sum(case when product_name is null or product_name = '' then 1 else 0 end) as product_name_null,
    sum(case when category_id is null or category_id = '' then 1 else 0 end) as category_null,
    sum(case when segment_id is null or segment_id = '' then 1 else 0 end) as segment_null,
    sum(case when style_id is null or style_id = '' then 1 else 0 end) as style_null,
    sum(case when category_name is null or category_name = '' then 1 else 0 end) as category_name_null,
    sum(case when segment_name is null or segment_name = '' then 1 else 0 end) as segment_name_null,
    sum(case when style_name is null or style_name = '' then 1 else 0 end) as style_name_null
from product_details;


/*
PROFILING SUMMARY — PRODUCT_DETAILS TABLE
- 12 unique products matching exactly with the sales table.
- 2 categories (Mens, Womens), 4 segments, 12 style names.
- No duplicates found.
- Data types are correctly defined, no errors.
- No NULL or blank values found in any column.
- No zero or outlier values in the price column.
- Table is in denormalized form — category, segment and style IDs
  with their names are combined into one table for easy reference.
*/
