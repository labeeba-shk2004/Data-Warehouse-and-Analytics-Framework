/*
===============================================================================
Quality Checks on Silver Layer
===============================================================================
Purpose:
    This script validates data in the 'silver' schema for:
    - Null or duplicate primary keys
    - Unwanted spaces in string fields
    - Standardization & consistency of values
    - Invalid date ranges or orders
    - Cross-field consistency checks

Usage:
    Run these checks after loading the Silver Layer.
    Investigate and resolve any discrepancies found.
===============================================================================
*/


-- ====================================================================
-- CRM Customer Info (silver.crm_cust_info)
-- ====================================================================

-- 1. Check for NULLs or duplicate primary keys (Expectation: No Results)
SELECT cst_id, COUNT(*) 
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- 2. Check for unwanted spaces (Expectation: No Results)
SELECT cst_key
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);

-- 3. Review standardized marital status values
SELECT DISTINCT cst_marital_status 
FROM silver.crm_cust_info;



-- ====================================================================
-- CRM Product Info (silver.crm_prd_info)
-- ====================================================================

-- 1. Check for NULLs or duplicate primary keys (Expectation: No Results)
SELECT prd_id, COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- 2. Check for unwanted spaces in product names (Expectation: No Results)
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- 3. Check for NULL or negative product costs (Expectation: No Results)
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- 4. Review standardized product line values
SELECT DISTINCT prd_line 
FROM silver.crm_prd_info;

-- 5. Check for invalid date ranges (start date > end date)
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;



-- ====================================================================
-- CRM Sales Details (silver.crm_sales_details)
-- ====================================================================

-- 1. Check for invalid due dates in source data (bronze layer)
--    Expectation: No invalid or out-of-range dates
SELECT NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
   OR LEN(sls_due_dt) != 8 
   OR sls_due_dt > 20500101 
   OR sls_due_dt < 19000101;

-- 2. Check invalid date orders (order date > ship/due date)
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- 3. Check consistency: Sales = Quantity * Price (Expectation: No Results)
SELECT DISTINCT sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL
   OR sls_sales <= 0 
   OR sls_quantity <= 0 
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;



-- ====================================================================
-- ERP Customer (silver.erp_cust_az12)
-- ====================================================================

-- 1. Identify out-of-range birthdates
--    Expectation: Between 1924-01-01 and today
SELECT DISTINCT bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' 
   OR bdate > GETDATE();

-- 2. Review standardized gender values
SELECT DISTINCT gen
FROM silver.erp_cust_az12;



-- ====================================================================
-- ERP Location (silver.erp_loc_a101)
-- ====================================================================

-- Review standardized country codes
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;



-- ====================================================================
-- ERP Product Category (silver.erp_px_cat_g1v2)
-- ====================================================================

-- 1. Check for unwanted spaces (Expectation: No Results)
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);

-- 2. Review standardized maintenance values
SELECT DISTINCT maintenance
FROM silver.erp_px_cat_g1v2;
