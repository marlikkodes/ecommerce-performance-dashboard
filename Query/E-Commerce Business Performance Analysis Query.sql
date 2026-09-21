--Input Data
-------------
create table if not exists customers_dataset(
	customer_id varchar (50) primary key not null,
	customer_unique_id varchar(50),
	custimer_zip_code_prefix varchar(50),
	customer_city varchar(50),
	customer_state varchar(50)
);

create table if not exists order_items_dataset(
	order_item_id varchar(50) primary key not null,
	order_id varchar(50),
	product_id varchar(50),
	seller_id varchar(50),
	shipping_limit_date date,
	price numeric,
	freight_value numeric
);

create table if not exists order_payments_dataset(
	order_id varchar(50),
	payment_sequential int,
	payment_type varchar(50),
	payment_installments int,
	payment_value numeric
);

create table if not exists order_reviews_dataset(
	review_id varchar(50) primary key not null,
	order_id varchar(50),
	review_score int,
	review_comment_title text,
	review_comment_message text,
	review_creation_date date,
	review_answe_timestamp date
);

create table if not exists orders_dataset(
	order_id varchar(50) primary key not null,
	customer_id varchar(50),
	order_status varchar(50),
	order_purchase_timestamp date,
	order_approved_at date,
	order_delivered_carrier_date date,
	order_delivered_customer_date date,
	order_estimated_delivery_date date
);

create table if not exists product_dataset(
	no int,
	product_id varchar(50) primary key not null,
	product_category_name varchar(50),
	product_name_lenght numeric,
	product_description_lenght numeric,
	product_photos_qty numeric,
	product_weight_g numeric,
	product_length_cm numeric,
	product_height_cm numeric,
	product_width_cm numeric
);

create table if not exists sellers_dataset(
	seller_id varchar(50)primary key not null,
	seller_zip_code_prefix varchar(50),
	seller_city varchar(50),
	seller_state varchar(50)
);

--Annual Customer Activity Growth Analysis
-------------------------------------------

--1.Monthly Active User

--Total Active User per Month
select 
	extract(year from order_purchase_timestamp) as year,
	extract(month from order_purchase_timestamp)as month,
	count(distinct cd.customer_unique_id) as total_active_user
from 
	orders_dataset as od
left join 
	customers_dataset as cd on od.customer_id = cd.customer_id
group by 1,2
order by 1,2;

--Total Active User per Day
select 
	order_purchase_timestamp,
	count(distinct cd.customer_unique_id) as total_active_user
from 
	orders_dataset as od
left join 
	customers_dataset as cd on od.customer_id = cd.customer_id
group by 1
order by 1;

--Monthly Active User
with total_active_user as (
	select 
		extract(year from order_purchase_timestamp) as year,
		extract(month from order_purchase_timestamp)as month,
		count(distinct cd.customer_unique_id) as total_customer
	from 
		orders_dataset as od
	left join 
		customers_dataset as cd on od.customer_id = cd.customer_id
	group by 1,2
	order by 1,2
)
select 
	year, 
	round(avg(total_customer),2) as avg_monthly_active_user
from 
	total_active_user 
group by 1
order by 1;

--2.Total new customers
with new_user as (  
	select
		cd.customer_unique_id,
		min(od.order_purchase_timestamp) as first_time_order
	from orders_dataset od
	inner join customers_dataset cd on cd.customer_id = od.customer_id
	group by 1
	order by 2
) 
select 
	extract(year from first_time_order) as year,
	count(distinct customer_unique_id) as new_user
from new_user
group by 1
order by 1;

--3.Total Users who Repeat Orders
with user_repeat_order as (
	select
		extract(year from od.order_purchase_timestamp) as year,
		cd.customer_unique_id,
		count(cd.customer_unique_id) as total_customer,
 		count(od.order_id) as total_order
	from orders_dataset as od
	join customers_dataset as cd on od.customer_id = cd.customer_id
	group by 1,2
	having count(order_id) >1
)
select 
	year, 
	count(total_customer) as user_repeat_order
from user_repeat_order
group by 1
order by 1;

--4.Average Order Per User
with total_order_user as (
	select 
		extract(year from od.order_purchase_timestamp) as year,
 		cd.customer_unique_id,
 		count(distinct order_id) as total_order
	from orders_dataset as od
	join customers_dataset as cd on od.customer_id = cd.customer_id
	group by 1,2
)
select 
	year, 
	round(avg(total_order),2) as avg_frequency_order
from total_order_user
group by 1
order by 1;

--5.Total Order
with total_order_customer as (
	select 
		extract(year from od.order_purchase_timestamp) as year,
		extract(month from od.order_purchase_timestamp) as month,
 		cd.customer_unique_id,
 		count(distinct order_id) as total_order
	from orders_dataset as od
	join customers_dataset as cd on od.customer_id = cd.customer_id
	group by 1,2,3
)
select 
	year,
	month, 
	round(sum(total_order),0) as total_order
from total_order_customer
group by 1,2
order by 1,2;

--Aggregation Annual Customer Activity Growth Analysis
with no1 as (
	with total_customer as (
	select 
		extract(year from order_purchase_timestamp) as year,
		extract(month from order_purchase_timestamp)as month,
		count(distinct cd.customer_unique_id) as total_customer
	from orders_dataset as od
	join customers_dataset as cd on od.customer_id = cd.customer_id
	group by 1,2
	order by 1,2
	)
	select 
		year, 
		round(avg(total_customer),2) as avg_monthly_active_user
	from total_customer 
	group by 1
	order by 1
),
no2 as (
	with new_customer as (  
	select
		cd.customer_unique_id,
		min(od.order_purchase_timestamp) as first_time_order
	from orders_dataset od
	inner join customers_dataset cd on cd.customer_id = od.customer_id
	group by 1
	) 
	select 
		extract(year from first_time_order) as year, 
		count(customer_unique_id) as count_new_customer
	from new_customer
	group by 1
	order by 1
),
no3 as (
	witH customer_repeat_order as (
	select
		extract(year from od.order_purchase_timestamp) as year,
		cd.customer_unique_id,
		count(cd.customer_unique_id) as total_customer,
 		count(od.order_id) as total_order
	from orders_dataset as od
	join customers_dataset as cd on od.customer_id = cd.customer_id
	group by 1,2
	having count(order_id) >1
	)
	select 
		year, 
		count(total_customer) as customer_repeat_order
	from customer_repeat_order
	group by 1
	order by 1
),
no4 as (
	with total_order_customer as (
	select 
		extract(year from od.order_purchase_timestamp) as year,
 		cd.customer_unique_id,
 		count(distinct order_id) as total_order
	from orders_dataset as od
	join customers_dataset as cd on od.customer_id = cd.customer_id
	group by 1,2
	)
	select 
		year, 
		round(avg(total_order),2) as avg_frequency_order
	from total_order_customer
	group by 1
	order by 1
),
no5 as (
	with total_order_customer as (
	select 
		extract(year from od.order_purchase_timestamp) as year,
		extract(month from od.order_purchase_timestamp) as month,
 		cd.customer_unique_id,
 		count(distinct order_id) as total_order
	from orders_dataset as od
	join customers_dataset as cd on od.customer_id = cd.customer_id
	group by 1,2,3
)
select 
	year,
	round(sum(total_order),0) as total_order
from total_order_customer
group by 1
order by 1
)
select 
	no1.year, 
	no1.avg_monthly_active_user, 
	no2.count_new_customer, 
	no3.customer_repeat_order, 
	no4.avg_frequency_order,
	no5.total_order
from no1
join no2
	on no1.year = no2.year
join no3
	on no1.year = no3.year
join no4
	on no1.year = no4.year
join no5
	on no1.year = no5.year
group by 1,2,3,4,5,6
order  by 1;

--Annual Product Category Quality Analysis
--------------------------------------------

--1.Total Revenue
create table total_revenue_per_year as
	with table_revenue_per_order as(
	select 
		order_id,
		price,
		freight_value,
		sum(price+freight_value) as revenue_per_order
	from order_items_dataset
	group by 1,2,3
	order by 1
	)
	select 
		extract(year from od.order_purchase_timestamp) as year,
		sum(revenue_per_order) as total_revenue
	from table_revenue_per_order as trpo
	join orders_dataset od on trpo.order_id = od.order_id
	where od.order_status = 'delivered'
	group by 1
	order by 1;
select * from total_revenue_per_year

create table total_revenue_per_month as
with table_revenue_per_order as(
select 
	order_id,
	price,
	freight_value,
	sum(price+freight_value) as revenue_per_order
from order_items_dataset
group by 1,2,3
order by 1)
select 
	extract(year from od.order_purchase_timestamp) as year,
	extract(month from od.order_purchase_timestamp) as month,
	sum(revenue_per_order) as total_revenue
from table_revenue_per_order as trpo
join orders_dataset od on trpo.order_id = od.order_id
where od.order_status = 'delivered'
group by 1,2
order by 1,2;
select * from total_revenue_per_month

--2.Total Canceled Order
create table total_canceled_per_year as
select
	extract(year from od.order_purchase_timestamp) as year,
	count(od.order_id) AS total_canceled
from orders_dataset as od
where order_status = 'canceled'
group by 1
order by 1;
select * from total_canceled_per_year

create table total_canceled_per_month as
select
	extract(year from od.order_purchase_timestamp) as year,
	extract(month from od.order_purchase_timestamp) as month,
	count(od.order_id) AS total_canceled
from orders_dataset as od
where order_status = 'canceled'
group by 1,2
order by 1,2;
select * from total_canceled_per_month

--3.Total Revenue Based On Product Category
create table highest_revenue_product_category as 
with ranking as (
	select 
		extract (year from  od.order_purchase_timestamp) as year,
		pd.product_category_name,
		sum(oid.price + oid.freight_value) as revenue,
		rank() over(
			partition by extract(year from od.order_purchase_timestamp) 
			order by sum(oid.price + oid.freight_value) desc) as rk
		from order_items_dataset as oid
		join orders_dataset od on od.order_id = oid.order_id
		join product_dataset pd on pd.product_id = oid.product_id
		where od.order_status = 'delivered'
		group by 1,2
	)
select
	year, 
	product_category_name, 
	revenue 
from ranking
where rk = 1;
select * from highest_revenue_product_category

--4.Total Canceled Order Based on Product Category
create table highest_canceled_product_category as
with ranking as(
	select 
		extract (year from  od.order_purchase_timestamp) as year,
		pd.product_category_name,
		count(od.order_id) as total_canceled,
		rank() over(
			partition by extract(year from od.order_purchase_timestamp) 
			order by count(od.order_id) desc) as rk
		from order_items_dataset as oid
		join orders_dataset od on od.order_id = oid.order_id
		join product_dataset pd on pd.product_id = oid.product_id
		where od.order_status = 'canceled'
		group by 1,2
	)
select
	year, 
	product_category_name, 
	total_canceled
from ranking
where rk = 1 ;
select * from highest_canceled_product_category

--Aggregation Annual Product Category Quality Analysis
select 
	trpy.year,
	trpy.total_revenue as total_revenue_per_year,
	hrpc.product_category_name as highest_revenue_product_category,
	tcpr.total_canceled as total_canceled_per_year,
	hcpc.product_category_name as highest_canceled_product_category
from total_revenue_per_year as trpy
join highest_revenue_product_category as hrpc
	on trpy.year = hrpc.year
join total_canceled_per_year as tcpr
	on hrpc.year = tcpr.year
join highest_canceled_product_category as hcpc
	on tcpr.year = hcpc.year
group by 1,2,3,4,5
order by 1;

--Annual Payment Type Usage Analysis
-------------------------------------

--1.Total Usage of Each Type of Payment
select 
	payment_type, 
	count(1) as total_of_uses
from order_payments_dataset as opd
join orders_dataset od on od.order_id = opd.order_id
group by 1
order by 2 desc;

--2.Total Usage of Each Type of Payment Per Year
select
	extract (year from od.order_purchase_timestamp) as year,
	opd.payment_type,
	count(2) as numbers_of_uses
from orders_dataset as od 
join order_payments_dataset as opd
	on od.order_id = opd.order_id
group by 1,2
order by 1,3 desc;

--3.The biggest payment value per year based on the type of payment
select
	extract (year from od.order_purchase_timestamp) as year,
	opd.payment_type,
	sum(opd.payment_value) as total_payment_value_per_year
from orders_dataset as od 
join order_payments_dataset as opd
	on od.order_id = opd.order_id
group by 1,2
order by 1,3 desc
