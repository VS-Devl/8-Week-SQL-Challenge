-- Section A: Customer Nodes Exploration

-- 1: How many unique nodes are there on the Data Bank system?
-- Logic: Basic distinct count to identify the breadth of the network infrastructure.
SELECT COUNT(DISTINCT node_id) AS unique_nodes 
FROM customer_nodes; 

-- 2: What is the number of nodes per region?
-- Logic: Grouping by region to see infrastructure density. 
-- Note: DISTINCT is required to count the unique nodes available in each region, 
-- rather than every historical allocation event.
SELECT 
    region_id, 
    COUNT(DISTINCT node_id) AS nodes_per_region
FROM customer_nodes 
GROUP BY region_id
ORDER BY region_id ASC;

