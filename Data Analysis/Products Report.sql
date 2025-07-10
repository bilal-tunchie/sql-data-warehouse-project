

/*
Product Report

Purpose:
	- This report consolidates key product metrics and behaviors.

Highlights:
	1. Gathers essential fields such as product name, category, subcategory, and cost.
	2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
	3. Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months)
	4. Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue
*/

CREATE VIEW gold.report_products AS
-- 1. Gathers essential fields such as product name, category, subcategory, and cost.
WITH Base_query AS (
	SELECT 
		f.order_number,
		f.customer_key,
		f.order_date,
		f.sales_amount,
		f.quantity,
		p.product_key,
		p.product_name,
		p.category,
		p.subcategory,
		p.cost
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
)

/* 
3. Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months)
*/
, product_aggregations AS (
	SELECT 
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		DATEDIFF(month, MIN(order_date), MAX(order_date)) lifespan,
		MAX(order_date) AS last_sale_date,
		COUNT(DISTINCT order_number) total_orders,
		COUNT(DISTINCT customer_key) total_customers,
		SUM(sales_amount) total_sales,
		SUM(quantity) total_quantity,
		ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
	FROM Base_query
	GROUP BY 
		product_key,
		product_name,
		category,
		subcategory,
		cost
)

/* 
2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
4. Calculates valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue
*/
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(month, last_sale_date, GETDATE()) recent_order_in_months,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performers'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performers'
	END AS product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,	
	total_customers,
	avg_selling_price,
	-- average order revenue (AOR)
	CASE WHEN total_orders = 0 THEN 0
		ELSE total_sales/ total_orders
	END AS avg_order_rev,
	-- average monthly revenue
	CASE WHEN lifespan = 0 THEN total_sales
		ELSE total_sales/ lifespan
	END AS avg_monthly_rev
FROM product_aggregations

SELECT * FROM gold.report_products
-- SELECT * FROM gold.dim_customers
-- SELECT * FROM gold.fact_sales
-- SELECT * FROM gold.dim_products
