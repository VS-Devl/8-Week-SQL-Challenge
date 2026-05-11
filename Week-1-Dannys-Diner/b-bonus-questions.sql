-- Bonus Question: Merge all tables data in a single table to avoid using Join everytime.
select s.customer_id, s.order_date, m.product_name, m.price, 
	CASE
		WHEN s.order_date < me.join_date THEN 'N'
        WHEN s.order_date >= me.join_date THEN 'Y'
        else 'N'
        END as members
from sales as s
join menu as m on s.product_id = m.product_id
left join members as me on s.customer_id = me.customer_id
ORDER BY s.customer_id, s.order_date, m.price desc;


CREATE TABLE IF NOT EXISTS dannys_sales(
customer_id varchar(5),
order_date DATE,
product_name VARCHAR(20) CHARACTER SET utf8mb4,
price INT,
members varchar(1)
); 


INSERT INTO dannys_sales(customer_id, order_date, product_name, price, members)
select 
	s.customer_id, 
	s.order_date, 
	m.product_name, 
	m.price, 
	CASE
		WHEN s.order_date < me.join_date THEN 'N'
        WHEN s.order_date >= me.join_date THEN 'Y'
        else 'N'
        END as members
from sales as s
join menu as m on s.product_id = m.product_id
left join members as me on s.customer_id = me.customer_id;


-- ranking the members on the basis of their memberships and orders after becoming a member
select *,
	CASE
		WHEN members = 'Y' THEN DENSE_RANK() OVER(PARTITION BY customer_id, members ORDER BY order_date)
        ELSE NULL
		END as ranking
from dannys_sales;


-- inserting some dummy data for testing rankings
INSERT INTO dannys_sales(customer_id, order_date, product_name, price, members) values 
("A", "2021-01-18", "sushi", "10", "Y"),
("D", "2021-01-02", "sushi", "10", "N"),
("B", "2021-02-02", "curry", "15","Y");
