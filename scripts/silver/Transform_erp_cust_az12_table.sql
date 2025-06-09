-- Checking Cloumns one by one

---- Remove the "NAS" from id to integrate it with key column in crm_cust_info table (cid)

SELECT 
	cid,
	CASE 
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END AS cid,
FROM bronze.erp_cust_az12

---- Check for Nulls or duplicates in primary key (cid)

SELECT 
	cid, 
	Count(*)
FROM bronze.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL

---- Check for customers age greater than today's date (bdate)

SELECT DISTINCT bdate
FROM bronze.erp_cust_az12
WHERE  bdate > GETDATE();

---- Check for unwanted spaces (gen)

SELECT gen
FROM bronze.erp_cust_az12
WHERE gen != TRIM(gen)

---- Data Standarization & Consistency (gen) 

SELECT DISTINCT gen
FROM bronze.erp_cust_az12

SELECT  DISTINCT
	gen,
	CASE 
		WHEN  UPPER(TRIM(gen)) in ('F', 'FEMALE') THEN 'Female'
		WHEN  UPPER(TRIM(gen)) in ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12


-- Transformation

---- Transform bronze.erp_cust_az12

------ Remove the "NAS" from id to integrate it with key column in crm_cust_info table (cid)
------ Check for Nulls or duplicates in primary key (cid)
------ Check for customers age greater than today's date (bdate)
------ Check for unwanted spaces (gen)
------ Data Standarization & Consistency (gen) 

---- Expectation: No Result

INSERT INTO silver.erp_cust_az12 (
	  cid,
    bdate,
	  gen
)


SELECT 
	CASE 
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END AS cid,
	CASE 
		WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END AS bdate,
    CASE 
		WHEN  UPPER(TRIM(gen)) in ('F', 'FEMALE') THEN 'Female'
		WHEN  UPPER(TRIM(gen)) in ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12
