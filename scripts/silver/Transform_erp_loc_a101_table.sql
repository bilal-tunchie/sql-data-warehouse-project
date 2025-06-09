-- Checking Cloumns one by one

---- Remove the "-" from id to integrate it with key column in crm_cust_info table (cid)

SELECT 
	cid,
	REPLACE(cid, '-', '') AS cid
FROM bronze.erp_loc_a101 

---- Check for Nulls or duplicates in primary key (cid)

SELECT 
	REPLACE(cid, '-', '') AS cid,
	Count(*)
FROM bronze.erp_loc_a101 
GROUP BY REPLACE(cid, '-', '') 
HAVING COUNT(*) > 1 OR REPLACE(cid, '-', '')  IS NULL

---- Check for unwanted spaces (cntry)

SELECT cntry
FROM bronze.erp_loc_a101 
WHERE cntry != TRIM(cntry)

---- Data Standarization & Consistency (cntry) 

SELECT DISTINCT cntry
FROM bronze.erp_loc_a101 

SELECT  DISTINCT
	cntry,
	CASE 
		WHEN TRIM(cntry) in ('US', 'USA') THEN 'United States'
		WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a'
		ELSE TRIM(cntry)
	END AS cntry
FROM bronze.erp_loc_a101 


-- Transformation

---- Transform bronze.erp_loc_a101 

------ Remove the "-" from id to integrate it with key column in crm_cust_info table (cid)
------ Check for Nulls or duplicates in primary key (cid)
------ Check for unwanted spaces (cntry)
------ Data Standarization & Consistency (cntry) 

---- Expectation: No Result

INSERT INTO silver.erp_loc_a101(
	  cid,
    cntry
)


SELECT 
	  REPLACE(cid, '-', '') AS cid,
    CASE 
		  WHEN TRIM(cntry) in ('US', 'USA') THEN 'United States'
		  WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		  WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a'
		  ELSE TRIM(cntry)
	 END AS cntry
FROM bronze.erp_loc_a101
