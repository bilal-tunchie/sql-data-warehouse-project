-- Checking Cloumns one by one

---- Check for Nulls or duplicates in primary key (prd_id)

SELECT 
	prd_id, 
	Count(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING  COUNT(*) > 1 OR prd_id IS NULL

---- Check for unwanted spaces (prd_nm)

SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

---- Check for Nulls or Negative Numbers (prd_cost)

SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL OR prd_cost < 0

---- Data Standarization & Consistency (cat_id)

SELECT DISTINCT SUBSTRING(prd_key, 1, 5) AS cat_id
FROM bronze.crm_prd_info;

SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;

---- Check for INVALID DATE ORDERS (prd_start_dt, prd_end_dt)

SELECT *
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt


-- Transformation

---- Transform bronze.crm_prd_info table

------ Check for Nulls or duplicates in primary key (prd_id)
------ Check for unwanted spaces (prd_nm)
------ Check for Nulls or Negative Numbers (prd_cost)
------ Data Standarization & Consistency (cat_id)
------ Check for INVALID DATE ORDERS (prd_start_dt, prd_end_dt)

---- Expectation: No Result

INSERT INTO Silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)

SELECT 
	prd_id,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
	prd_nm,
	ISNULL(prd_cost, 0) AS prd_cost,
	CASE UPPER(TRIM(prd_line))
		WHEN  'M' THEN 'Mountain' 
		WHEN  'R' THEN 'Road' 
		WHEN  'S' THEN 'Other Sales' 
		WHEN  'T' THEN 'Touring' 
		ELSE 'n/a'
	END AS prd_line,
	CAST(prd_start_dt AS DATE) AS prd_start_dt,
	CAST(DATEADD(day, -1, LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)) AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info
