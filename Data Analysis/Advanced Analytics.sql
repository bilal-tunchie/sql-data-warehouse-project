USE DataWarehouse;

------ ****** Change over time ****** ------
	
---- Analyze sales performance over time

SELECT 
    YEAR(order_date) AS years,
	MONTH(order_date) AS months,
	SUM(sales_amount) AS rev_by_years,
	COUNT(DISTINCT customer_key) AS customers,
	SUM(quantity) AS quantity
FROM gold.fact_sales
GROUP BY YEAR(order_date), MONTH(order_date)
HAVING MONTH(order_date) IS NOT NULL
ORDER BY years, months

--************************************--

------ ****** Cumulative Analysis ****** ------
	
---- Aggregate the data progressively over time

SELECT *,SUM(rev_by_years) OVER(PARTITION BY year(month_)  ORDER BY month_)
FROM (
	SELECT 
		DATETRUNC(month, order_date) AS month_,
		SUM(sales_amount) AS rev_by_years
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(month, order_date)
	--ORDER BY month_
)t

--************************************--

------ ****** Performance Analysis ****** ------
	
/*---- Analyze the yearly performance of products by comparing their sales
 to both the average sales performance of the product and the previous year's sales */

WITH yearly_products_sales AS (
	SELECT 
		YEAR(f.order_date) order_year,
		p.product_name,
		SUM(f.sales_amount) current_year
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
	GROUP BY p.product_name, YEAR(f.order_date)
)


SELECT 
	*, 
	AVG(current_year) OVER(PARTITION BY product_name) AS avg_product_sales,
	current_year - AVG(current_year) OVER(PARTITION BY product_name) AS diff_avg,
	CASE
		WHEN current_year - AVG(current_year) OVER(PARTITION BY product_name) > 0 THEN 'Above avg'
		WHEN current_year - AVG(current_year) OVER(PARTITION BY product_name) < 0 THEN 'Below avg'
		ELSE 'avg'
	END AS avg_status,
	lag(current_year) over(PARTITION BY product_name ORDER BY order_year) AS previous_year,
	current_year - lag(current_year) over(PARTITION BY product_name ORDER BY order_year)  AS diff_previous,
	CASE
		WHEN current_year - lag(current_year) over(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increasing'
		WHEN current_year - lag(current_year) over(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decreasing'
		ELSE 'No Change'
	END AS avg_status
FROM yearly_products_sales 
ORDER BY product_name, order_year

--************************************--

------ ****** Part-to-whole ****** ------
	
/*---- Analyze how an individual part is performing compared to the overall,
allowing us to understand which category has the greatest impact on the business. */

---- Which categories contribute the most to overall sales?
SELECT 
	category,
	sales_by_category,
	sum(sales_by_category) OVER() Total_sales,
	CONCAT(ROUND(CAST(sales_by_category AS FLOAT) / sum(sales_by_category) OVER() * 100, 2), '%')  AS percentage_
FROM(
	SELECT 
		p.category,
		sum(f.sales_amount) sales_by_category
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
	GROUP BY p.category
)t
ORDER BY sales_by_category DESC

--************************************--

------ ****** Data Segmentation ****** ------
	
/*---- Group the data based on a specific range.
Helps understand the correlation between two measures. ----*/

/*---- Segment products into cost ranges and
count how many products fall into each segment. ----*/

SELECT *, COUNT(product_name) OVER(PARTITION BY SEGMENT) AS number_of_products_by_segment
FROM(
	SELECT 
		product_name,
		cost,
		CASE
			WHEN cost BETWEEN 0 AND 750 THEN 'LOW'
			WHEN cost BETWEEN 750 AND 1500 THEN 'MEDIUM'
			WHEN cost > 1500  THEN 'HIGH'
		END AS segment
	
	FROM gold.dim_products
)t
ORDER BY cost

/*---- 
Group customers into three segments based on their spending behavior:

- VIP: at least 12 months of history and spending more than €5,000.
- Regular: at least 12 months of history but spending €5,000 or less.
- New: lifespan less than 12 months.

And find the total number of customers by each group.
----*/

WITH customer_spending AS (
	SELECT
		c.customer_key,
		SUM(f.sales_amount) AS total_spending,
		MIN(f.order_date) AS first_order,
		MAX(f.order_date) AS last_order,
		DATEDIFF( month, MIN(f.order_date), MAX(f.order_date) ) AS lifespan
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
	GROUP BY c.customer_key
)

SELECT
	customer_segment,
	COUNT(customer_key) AS total_customers
FROM(
	SELECT
		customer_key,
		total_spending,
		lifespan,
		CASE
			WHEN total_spending > 5000 AND lifespan >= 12 THEN 'VIP'
			WHEN total_spending <= 5000 AND lifespan >= 12 THEN 'Regular'
			ELSE 'NEW'
		END AS customer_segment
	FROM customer_spending
)t3
GROUP BY customer_segment
ORDER BY total_customers DESC
