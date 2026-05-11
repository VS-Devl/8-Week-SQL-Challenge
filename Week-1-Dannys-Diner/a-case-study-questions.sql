
-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
    s.customer_id, 
    SUM(m.price) AS total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;
  
-- 2. How many days has each customer visited the restaurant?  
select customer_id, count(DISTINCT order_date) as visited_date
from sales
GROUP BY customer_id;  


-- 3. What was the first item from the menu purchased by each customer?
with cte as (
select *,
dense_rank() over(PARTITION BY customer_id order by order_date) as rn
from sales
)
select cte.customer_id, m.product_name
from cte
JOIN menu as m
on cte.product_id = m.product_id
where rn = 1
GROUP BY cte.customer_id, m.product_name;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, count(s.product_id) as total_sales
from menu as m
join sales as s
on m.product_id = s.product_id
group by m.product_name
ORDER BY total_sales desc
limit 1;


with order_count as(
select m.product_name, count(s.product_id) as total_sales
from sales as s
join menu as m
on s.product_id = m.product_id
group by m.product_name
),
item_rank as(
select *,
DENSE_RANK() over(ORDER BY total_sales desc) as rn 
from order_count
)
select * from item_rank;


-- 5. Which item was the most popular for each customer?
with order_count as(
select s.customer_id, m.product_name, count(s.product_id) as total_sales
from sales as s 
join menu as m
on s.product_id = m.product_id
group by s.customer_id, m.product_name
),
item_rank as(
select *,
DENSE_RANK() over(PARTITION BY customer_id ORDER BY total_sales desc) as rn
from order_count
)
SELECT customer_id, product_name, total_sales
from item_rank
where rn = 1;


-- 6. Which item was purchased first by the customer after they became a member?
with order_cte as(
select s.customer_id, m.product_name,
DENSE_RANK() over(PARTITION BY s.customer_id order by s.order_date) as first_order
from sales as s
join menu as m on s.product_id = m.product_id
join members as me on s.customer_id = me.customer_id
where me.join_date >= s.order_date
)
SELECT customer_id, product_name
from order_cte
where first_order = 1;


-- 7. Which item was purchased just before the customer became a member?
with order_cte as(
select s.customer_id, m.product_name,
DENSE_RANK() over(PARTITION BY s.customer_id order by s.order_date) as first_order
from sales as s
join menu as m on s.product_id = m.product_id
join members as me on s.customer_id = me.customer_id
where me.join_date < s.order_date
)
SELECT customer_id, product_name
from order_cte
where first_order = 1;


-- 8. What is the total items and amount spent for each member before they became a member?
with order_cte as(
select s.customer_id,count(s.product_id) as total_items, sum(m.price) as total_amount
from sales as s
join menu as m on s.product_id = m.product_id
join members as me on s.customer_id = me.customer_id
where me.join_date < s.order_date
group by customer_id
)
SELECT customer_id, total_items, total_amount
from order_cte;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with points_cte as(
select s.customer_id,
SUM(CASE	
	WHEN m.product_name = 'sushi' then m.price * 20
    ELSE m.price * 10
	END) as points
from sales as s 
join menu as m
on s.product_id = m.product_id
GROUP BY s.customer_id
)
select customer_id, points
from points_cte;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?
WITH points_cte AS(
	SELECT s.customer_id,
	SUM(CASE	
		WHEN s.order_date BETWEEN me.join_date AND date_add(me.join_date, INTERVAL 6 DAY) THEN m.price * 20
		WHEN m.product_name = 'sushi' THEN m.price * 20
		ELSE m.price * 10
		END) AS points
FROM sales AS s 
JOIN menu AS m 
ON s.product_id = m.product_id
JOIN members AS me 
ON s.customer_id = me.customer_id
WHERE 
	me.customer_id IN ('A','B') AND
	s.order_date <= '2021-01-31'
GROUP BY s.customer_id
)
SELECT customer_id, points
FROM points_cte;

