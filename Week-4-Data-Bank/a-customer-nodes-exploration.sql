-- Section A: Customer Nodes Exploration

-- 1: How many unique nodes are there on the Data Bank system?
-- Logic: Basic distinct count to identify the breadth of the network infrastructure.
SELECT COUNT(DISTINCT node_id) AS unique_nodes 
FROM customer_nodes; 
