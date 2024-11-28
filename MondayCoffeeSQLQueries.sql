--Monday Coffee Data Analysis

select *
from city;

select * 
from products;

select *
from customers;

select *
from sales;

--Business Problems and Data Analysis

--1. How many people in each city are estimated to consume coffee given 25% of the population does?

select city_name,
round((population * 0.25)/1000000,2) as coffee_consumers_million, city_rank
from city
order by 2 desc;

--2. What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select ci.city_name, sum(s.total) as Total_Revenue
from sales as s
inner join customers as c
on s.customer_id = c.customer_id
inner join city ci
on ci.city_id = c.city_id
where (extract(year from s.sale_date) = 2023)
and 
(extract(quarter from s.sale_date) = 4)
group by 1;


--3. How many units of each coffee product have been sold?

select p.product_name, count(s.sale_id) as total_orders
from products as p
left join 
sales as s
on s.product_id = p.product_id
group by 1;


--4. What is the average sales amount per customer in each city?

select  ci.city_name, count(distinct s.customer_id) as total_Customer,
sum(s.total)/count(distinct s.customer_id) as per_city_avg_Sale
from sales as s
inner join customers as c
on s.customer_id = c.customer_id
inner join city ci
on ci.city_id = c.city_id
group by 1
order by 2 desc


--5. Provide a list of cities along with their populations and estimated coffee consumers.
WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name


--6. What are the top 3 selling products in each city based on sales volume?
select * from 
(
select ci.city_name, p.product_name, count(s. Sale_id) as total_orders,
dense_rank() over(partition by ci.city_name order by count(s. Sale_id)desc) as rank
from sales as s
inner join products as p
on s.product_id = p.product_id
inner join customers as c
on c.customer_id = s.customer_id
inner join city as ci
on ci.city_id = c.city_id
group by 1, 2) as t1
where rank <=3;

--7. How many unique customers are there in each city who have purchased coffee products?


select  ci.city_name, count(distinct c.customer_id) as unique_total_Customer
from city as ci
left join customers as c
on c.city_id = ci.city_id
inner join sales as s
on s.customer_id = c.customer_id
where s. product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by 1;


--8. Find each city and their average sale per customer and avg rent per customer

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent
FROM city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC



-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.
