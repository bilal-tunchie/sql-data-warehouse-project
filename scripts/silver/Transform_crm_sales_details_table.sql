-- Checking Cloumns one by one

---- Check for Zero, Nulls and Negative Numbers for sales (sls_sales, sls_quantity, sls_price)

SELECT DISTINCT
	*
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
	OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
	OR sls_sales <= 0  OR sls_quantity <= 0  OR sls_price <= 0 
ORDER BY sls_sales, sls_quantity, sls_price	

---- Check for INVALID DATE ORDERS (sls_order_dt, sls_ship_dt, sls_due_dt)

SELECT *
FROM bronze.crm_sales_details
where sls_order_dt > sls_ship_dt  OR sls_ship_dt > sls_due_dt


-- Transformation

---- Transform bronze.crm_sales_details

------ Check for Zero, Nulls and Negative Numbers for sales (sls_sales, sls_quantity, sls_price)
------ Check for INVALID DATE ORDERS (sls_order_dt, sls_ship_dt, sls_due_dt)

---- Expectation: No Result

INSERT INTO silver.crm_sales_details (
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
)


SELECT 
	    sls_ord_num,
	    sls_prd_key,
	    sls_cst_id AS sls_cust_id,
			CASE 
				WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END AS sls_order_dt,
			CASE 
				WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END AS sls_ship_dt,
			CASE 
				WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END AS sls_due_dt,
			CASE 
				WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
					THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END AS sls_sales, -- Recalculate sales if original value is missing or incorrect
			sls_quantity,
			CASE 
				WHEN sls_price IS NULL OR sls_price <= 0 
					THEN sls_sales / NULLIF(sls_quantity, 0)
				ELSE sls_price  -- Derive price if original value is invalid
			END AS sls_price
FROM bronze.crm_sales_details
