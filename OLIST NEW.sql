--- PROJECT ON OLIST

--Q.1 Count total orders
select count(distinct order_id) as total_orders 
from olist_master_cleaned

--Q.2 Count customers by state
select customer_state, count(distinct customer_id) as total_customers
from olist_master_cleaned
group by customer_state 
order by total_customers 

--Q.3 Find total revenue
select sum(payment_value) as total_revenue
from olist_master_cleaned

--Q.4 in these may be dublicate value are there so i m using main data
select sum(payment_value) as total_revenue
from olist_order_payments_dataset

--Q.5 Find number of orders per customer
select customer_id,count(distinct order_id) as no_of_order
from olist_master_cleaned
group by customer_id

--Find top 5 cities with highest number of orders
select customer_city, count(distinct order_id) as highest_orders
from olist_master_cleaned
group by customer_city 
order by highest_orders desc
limit 5;

with city_order as
(select customer_city,count(distinct order_id) as highest_orders
from olist_master_cleaned
group by customer_city)
select * from city_order 
order by highest_orders desc limit 5;

--Q.6 Find monthly sales trend (revenue by month)
select DATE_TRUNC('month',order_purchase_timestamp) AS month,
sum(payment_value) as revenue
from olist_master_cleaned
group by month
order by month desc

with cte as 
(SELECT date_trunc ('month',o.order_purchase_timestamp) as month,
sum(p.payment_value) as revenue
from olist_orders_dataset as o
join olist_order_payments_dataset as p
on o.order_id = p.order_id
group by month)
select * from cte 
order by month desc;

--Q.7 Find Top 10 Products by Revenue
with cte as 
(select product_id,sum(price) as revenue
from olist_master_cleaned
group by product_id)
select * from cte
order by revenue desc
limit 10


--Q.8 Top 5 states by revenue
with cte as 
(select customer_state,sum(price) as revenue
from olist_master_cleaned
group by customer_state)
select * from cte
order by revenue desc
limit 5

--Q.9 Average order value (AOV)
--AOV = total revenue / total orders
--first we have calculate order value by summing price then take avg of order value
--then these is average order value
with cte as 
(select order_id,sum(price)as order_value
from olist_master_cleaned
group by order_id)
select avg(order_value) as avg_order_value from cte 

--Q.10 Find customers who placed more than 1 order (repeat customers)
select customer_id,count(distinct order_id) as total_orders
from olist_master_cleaned
group by customer_id
having count(distinct order_id) > 1;

--Q.11 Revenue by payment type
with cte as 
(select payment_type,sum(payment_value) as revenue
from olist_order_payments_dataset
group by payment_type)
select * from cte 
order by revenue desc
--Q.12 Find total orders per seller
with cte as
(select seller_id,count(distinct order_id) as total_orders
from olist_master_cleaned
group by seller_id)
select * from cte
order by total_orders desc;


--Q.13 Find percentage contribution of each product to total revenue
with cte as
(select product_id,sum(price) as total_revenue
from olist_master_cleaned
group by product_id)
select product_id,total_revenue,
round(total_revenue*100.0/sum(total_revenue)over(),2) as contribution_percent
from cte order by contribution_percent desc;


--Q.14 Rank top sellers by revenue
with cte1 as 
(select seller_id,sum(price)as revenue
from olist_master_cleaned 
group by seller_id),

cte2 as
(select *,
dense_rank() over(order by revenue desc) as rnk
from cte1)

select * from cte2 where rnk <=5;


--Q.15 Rank top 5 sellers by revenue using RANK()
select seller_id,sum(price) as revenue
from olist_master_cleaned
group by seller_id
order by revenue desc limit 5


--Q.16 Find top 20% customers contributing to revenue (Pareto)
with cte1 as 
(select customer_id,sum(payment_value) as total_revenue
from olist_master_cleaned
group by customer_id),
cte2 as(select *, ntile(5) over(order by total_revenue desc) as percentile_group
from cte1)
select * from cte2 where percentile_group = 1;


--Q.17 Find average delivery time per state

with cte as
(select customer_state, 
avg(order_delivered_customer_date - order_purchase_timestamp) as avg_delivery_Date
from olist_master_cleaned
where order_delivered_customer_date is not null
group by customer_state
)
select * from cte 
order by avg_delivery_date desc




--Q.18 Find late deliveries and percentage of late orders
with cte as
(select count(*)
filter(where order_delivered_customer_date is not null and
order_delivered_customer_date > order_estimated_delivery_date) as late_delivery,
count(*) as total_orders
from olist_master_cleaned)
select late_delivery,total_orders,
round(late_delivery * 100.0/total_orders,2) as late_percentage
from cte


--Q.19 Find most profitable product category (use price)
select product_id,product_category_name,
sum(COALESCE (price,0)) as total_revenue
from olist_master_cleaned
group by product_id,product_category_name
order by total_revenue desc limit 3

--Q.20 Find customers who haven’t ordered again after first purchase
select customer_id,order_id from olist_master_cleaned
group by customer_id,order_id
having count(distinct order_id) = 1


--Q.21 Why is revenue dropping in a certain month?
select date_trunc('month',order_purchase_timestamp) as month,
count(distinct order_id) as total_order
from olist_master_cleaned
group by month
order by month


--Q.22 Which customers should we target for retention?
select customer_id,count(distinct order_id)as total_orders,
sum(COALESCE(payment_value,0)) as total_purchase
from olist_master_cleaned 
group by customer_id 
order by total_purchase desc
limit 20



--Q.23 Which sellers are underperforming?
with cte as
(select seller_id,sum(price) as seller_revenue 
from olist_master_cleaned
group by seller_id)
select * from cte 
order by seller_revenue asc
limit 10

--with window function
with cte as
(select seller_id,sum(price) as seller_revenue,
rank() over(order by sum(price) asc)as rnk
from olist_master_cleaned
group by seller_id)
select * from cte
where rnk <= 10  --these top 10 seller are under performing on revenue

--% of late order 

with cte as 
(select seller_id, count(distinct order_id)as total_orders,
count(distinct order_id) 
filter(where order_delivered_customer_date > order_estimated_delivery_date)
as late_order from olist_master_cleaned
where order_delivered_customer_date is not null
group by seller_id)
select seller_id,total_orders,late_order,
round(late_order*100.0/total_orders,2) as late_percentage
from cte where total_orders>20
order by late_percentage desc


--Q.24 How will you identify delivery issues?

--Late order
with cte as
(select count(*) filter
(where order_delivered_customer_date > order_estimated_delivery_date)
as late_delivery
from olist_master_cleaned
where order_delivered_customer_date is not null)

select * from cte

--avg delivery time
with cte as 
(select avg(order_delivered_customer_date - order_purchase_timestamp)
as avg_delivery_time
from olist_master_cleaned
where order_delivered_customer_date is not null)

select * from cte

--state by avg time
with cte as
(select customer_state,
avg(order_delivered_customer_date - order_purchase_timestamp)
as avg_delivery_time
from olist_master_cleaned
WHERE order_delivered_customer_date IS NOT NULL
group by customer_state)
select * from cte
order by avg_delivery_time desc

--undelivered order 
select count(*) from olist_master_cleaned
where order_delivered_customer_date is null



