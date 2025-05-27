-- Checking Cloumns one by one

---- Check for Nulls or duplicates in primary key (cst_id)

SELECT 
	cst_id, COUNT(*)
FROM Silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT (*) > 1 OR cst_id IS NULL

---- Check for unwanted spaces (cst_firstName, cst_lastName)

SELECT 
	cst_firstName
FROM bronze.crm_cust_info
WHERE cst_firstName != trim(cst_firstName)

---- Data Standarization & Consistency (cst_martial_status, cst_gndr)

SELECT DISTINCT
	cst_martial_status
FROM bronze.crm_cust_info;


-- Transformation

---- Transform bronze.crm_cust_info table

------ Check for Nulls or duplicates in primary key (cst_id)
------ Check for unwanted spaces (cst_firstName, cst_lastName)
------ Data Standarization & Consistency (cst_martial_status, cst_gndr)

---- Expectation: No Result

SELECT 
	cst_id,
	cst_key, 
	trim(cst_firstName) AS cst_firstName,
	trim(cst_lastName) AS cst_lastName,
	CASE 
		WHEN UPPER(TRIM(cst_martial_status)) = 'M' THEN 'Married' 
		WHEN UPPER(TRIM(cst_martial_status)) = 'S' THEN 'Single' 
		ELSE 'n/a'
	END AS cst_martial_status,
	CASE 
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' 
		WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' 
		ELSE 'n/a'
	END AS cst_gndr,
	cst_create_date
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY cst_id order by cst_create_date DESC) as Flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
)t 
WHERE Flag_last = 1
