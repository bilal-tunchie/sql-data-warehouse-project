--USE DataWarehouse;

------ ****** Part-to-whole ****** ------
/*
==================================================================================
Customer Report
==================================================================================
Purpose:
	- This report consolidates key customer metrics and behaviors

Highlights:
	1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
		- lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since last order)
		- average order value
		- average monthly spend
==================================================================================
*/

/*
----------------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
----------------------------------------------------------------------------------
*/
CREATE VIEW gold.report_customers AS 
WITH Base_query AS (
	SELECT 
		f.order_number,
		f.product_key,
		f.order_date,
		f.sales_amount,
		f.quantity,
		c.customer_key,
		c.customer_number,
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		DATEDIFF( year, c.birthdate, CAST(GETDATE() AS DATE) ) AS age
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
	WHERE f.order_date IS NOT NULL
)

-- 3. Aggregates customer-level metrics:
, customer_aggregations AS (
	SELECT 
		customer_key,
		customer_number,
		customer_name,
		age,
		COUNT(DISTINCT order_number) total_orders,
		SUM(sales_amount) total_sales,
		SUM(quantity) total_quantity,
		COUNT(DISTINCT product_key) total_products,
		MAX(order_date) AS last_order_date,
		DATEDIFF(month, MIN(order_date), MAX(order_date)) lifespan
	FROM Base_query
	GROUP BY customer_key, customer_number, customer_name, age
)

-- 2. Segments customers into categories (VIP, Regular, New) and age groups.
-- 4. Calculates valuable KPIs:

SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE
		WHEN age < 20 THEN 'Teens'
		WHEN age BETWEEN 20 AND  29 THEN '20-29'
		WHEN age BETWEEN 30 AND  39 THEN '30-39'
		WHEN age BETWEEN 40 AND  49 THEN '40-49'
		ELSE 'Above 49'
	END AS ages_group,
	CASE
		WHEN total_sales > 5000 AND lifespan >= 12 THEN 'VIP'
		WHEN total_sales <= 5000 AND lifespan >= 12 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	last_order_date,
	DATEDIFF(month, last_order_date, GETDATE()) recent_order_in_months,
	lifespan,
	CASE WHEN total_orders = 0 THEN 0
		ELSE total_sales/ total_orders
	END AS avg_order_value,
	CASE WHEN lifespan = 0 THEN total_sales
		ELSE total_sales/ lifespan
	END AS avg_monthly_spend
FROM customer_aggregations


SELECT * FROM gold.report_customers;

--SELECT * FROM gold.dim_customers
--SELECT * FROM gold.fact_sales
--SELECT * FROM gold.dim_products
