USE DataWarehouse;

-- Explore All Objects in the Database
SELECT * FROM INFORMATION_SCHEMA.TABLES

-- Explore All Columns in the Database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS

SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers'

--************************************--

-- Dimension Exploration

---- Customers Dimensions
SELECT * FROM gold.dim_customers
SELECT DISTINCT country FROM gold.dim_customers

---- Products Dimensions
SELECT * FROM gold.dim_products
SELECT DISTINCT category, subcategory FROM gold.dim_products
SELECT DISTINCT 
	category, subcategory, product_name 
FROM 
gold.dim_products
ORDER BY 1,2,3

--************************************--

-- DATE Exploration 
--- * Identify the earliest and latest dates (boundaries)
--- * Understand the scope of data and timespan ( do we have 2 years or 10 years?)

---- Customers Dates
SELECT * FROM gold.dim_customers
SELECT DATEDIFF(year, MIN(birthdate), CAST(GETDATE() AS DATE)), DATEDIFF(year, MAX(birthdate), CAST(GETDATE() AS DATE))
FROM gold.dim_customers

---- Sales Dates
SELECT * FROM gold.fact_sales
SELECT MIN(order_date), MAX(order_date), DATEDIFF(year, MIN(order_date), MAX(order_date))
FROM gold.fact_sales

--************************************--

-- Measures Exploration
--- Calculate the key metrics of the business (Calculate the highest and lowest level of aggregation)

--- Total Sales
SELECT * FROM gold.fact_sales

SELECT FORMAT(SUM(sales_amount), 'N') AS TotalSales
FROM gold.fact_sales

--- Total Quantity
SELECT FORMAT(SUM(quantity), 'N') AS TotalQuantity
FROM gold.fact_sales

--- Average Selling price
SELECT FORMAT(AVG(price), 'N') AS AvgPrice
FROM gold.fact_sales

--- Total Of Orders
SELECT  FORMAT(COUNT(DISTINCT order_number), 'N0') AS total_orders_number
FROM gold.fact_sales

--- Total Of Products
SELECT * FROM gold.dim_products

SELECT DISTINCT FORMAT(COUNT(product_key), 'N0') AS total_products_number
FROM gold.dim_products

--- Total Of customers
SELECT * FROM gold.dim_customers

SELECT FORMAT(COUNT(customer_key), 'N0') AS total_customers_number
FROM gold.dim_customers

--- Total Of customers that has placed an order
SELECT COUNT(DISTINCT customer_key) AS total_customers_placed_order
FROM gold.fact_sales 

------ ****** The big picture about the key metrics ****** ------

SELECT 'Total Sales' AS measure_name, FORMAT(SUM(sales_amount), 'N') AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total quantity', FORMAT(SUM(quantity), 'N0') FROM gold.fact_sales
UNION ALL
SELECT 'Average Selling price', FORMAT(AVG(price), 'N') FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', FORMAT(COUNT(DISTINCT order_number), 'N0') FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', FORMAT(COUNT(product_key), 'N0') FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', FORMAT(COUNT(customer_key), 'N0') FROM gold.dim_customers
