CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);

CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);


INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');

--1. What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(m.price) as total_spent from sales s
join menu m
on s.product_id=m.product_id
group by s.customer_id;

-- 2. How many days has each customer visited the restaurant?
select s.customer_id, count(distinct s.order_date)as days_visited from sales s
group by s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
--checking for the first purchase date of each customers first
select s.customer_id, min(s.order_date)as first_purchase_date  
from sales s
group by s.customer_id;      
--quering the first item purchase with the first purchase date we create a temporary table
with customer_first_purchase_date as(select s.customer_id, min(s.order_date)as first_purchase_date  
from sales s
group by s.customer_id)
select cfpd.customer_id,cfpd.first_purchase_date,m.product_name
from customer_first_purchase_date cfpd
join sales s 
on cfpd.customer_id=s.customer_id
and cfpd.first_purchase_date=s.order_date
join menu m
on m.product_id=s.product_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name,count(m.product_name) as total_purchased
from sales s
join menu m
on s.product_id=m.product_id
group by m.product_name
order by total_purchased desc
limit 1;

-- 5. Which item was the most popular for each customer?
select s.customer_id,count(m.product_name) as purchase_count, m.product_name
from sales s
join menu m
on s.product_id=m.product_id
group by s.customer_id, m.product_name
order by purchase_count desc;
--The above query shows the count of purchased by each customer, to show the most popular for all customers we can use this query instead
with customer_most_popular_item as(select s.customer_id,count(m.product_name) as purchase_count,m.product_name,
dense_rank()over (partition by s.customer_id order by count(m.product_name) desc) as rank 
from sales s
join menu m
on s.product_id=m.product_id
group by s.customer_id,m.product_name)
select cmpi.customer_id,cmpi.product_name,cmpi.purchase_count
from customer_most_popular_item cmpi
where rank=1;

-- 6. Which item was purchased first by the customer after they became a member?
with Purchase_after_membership as(select s.customer_id, min(s.order_date)as first_purchase_date, m.product_name,
dense_rank()over (partition by s.customer_id order by min(s.order_date)) as rank 
from sales s
join members mb
on mb.customer_id=s.customer_id
join menu m
on m.product_id=s.product_id
where s.order_date >=mb.join_date
group by s.customer_id,m.product_name)
select pam.customer_id,pam.product_name
from Purchase_after_membership pam
where rank=1;
select*from sales;



-- 7. Which item was purchased just before the customer became a member?
with Last_Purchase_before_membership as(select s.customer_id, max(s.order_date)as first_purchase_date, m.product_name,
dense_rank()over (partition by s.customer_id order by max(s.order_date)desc) as rank 										
from sales s
join members mb
on mb.customer_id=s.customer_id
join menu m
on m.product_id=s.product_id
where s.order_date < mb.join_date
group by s.customer_id,m.product_name)
select lpbm.customer_id,lpbm.product_name
from Last_Purchase_before_membership lpbm
where rank=1;

-- 8. What is the total items and amount spent for each member before they became a member?
select  s.customer_id, count(m.product_name)as total_items,sum(price)									
from sales s
join members mb
on mb.customer_id=s.customer_id
join menu m
on m.product_id=s.product_id
where s.order_date < mb.join_date
group by s.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select s.customer_id, sum(
case
when m.product_name='sushi' then m.price*20
else m.price*10 end) as total_points
from sales s
join menu m on s.product_id=m.product_id
group by s.customer_id;


/* 10. In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/
select s.customer_id, sum(
case
	when s.order_date between mb.join_date and mb.join_date + INTERVAL '7 days'
	then m.price*20
	when m.product_name='sushi' then m.price*20
	else m.price*10 end) as total_points
from sales s
join menu m on s.product_id=m.product_id
left join members mb on s.customer_id=mb.customer_id
where s.customer_id in ('A','B') and s. order_date<='2021-01-31'
group by s.customer_id;


--11. Recreate the table output using the available data
select s.customer_id, s.order_date, m.product_name, m.price,
case
	WHEN s.order_date>=mb.join_date then 'y'
	else 'N' end as member 
	from sales s
join menu m on s.product_id=m.product_id
left join members mb on s.customer_id=mb.customer_id
order by s.customer_id,s.order_date;


--12. Rank all the things IN THE TABLE CREATED FROM 11:
with customer_details as (select s.customer_id, s.order_date, m.product_name, m.price,
case
	WHEN s.order_date>=mb.join_date then 'y'
	else 'N' end as member 
	from sales s
join menu m on s.product_id=m.product_id
left join members mb on s.customer_id=mb.customer_id
order by s.customer_id,s.order_date)
select *,
case
when member='N' then null
else rank() over(partition by customer_id, member order by order_date)
end as rankings
from customer_details
order by customer_id, order_date;


