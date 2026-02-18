-- =============================================
-- File: 02_cleaning_staging.sql
-- Purpose: Clean raw retail data and create staging table
-- =============================================

-- =============================================
-- 1. RAW FINANCIAL BASELINE METRICS
-- Purpose: Establish control totals from the raw dataset
--          before any cleaning or transformation.
--          These figures serve as reconciliation checkpoints.
-- =============================================

-- A. Gross Revenue 
-- Total revenue generated from positive sales transactions. 
SELECT SUM(Quantity * Price) AS Gross_Revenue
FROM online_retail_raw 
WHERE Quantity > 0

-- B. Refund Value
-- Total value of customer cancellations. Identified by cancellation invoices (Invoice LIKE 'C%') and negative quantity.
SELECT SUM(Quantity * Price) AS Refund_Value
FROM online_retail_raw
WHERE Invoice LIKE 'C%' AND Quantity < 0

-- C. Net Revenue 
-- Total transactional revenue including both sales and cancellations.
SELECT SUM(Quantity * Price) AS Net_Revenue
FROM online_retail_raw

-- D. Distinct Invoice Count 
-- Total number of unique invoice identifiers
SELECT COUNT(DISTINCT Invoice) AS Distinct_Invoice
FROM online_retail_raw

-- E. Distinct Customer Count
-- Total number of unique customers
SELECT COUNT(DISTINCT Customer_ID) AS Distinct_Customers
FROM online_retail_raw

-- F. Total Positive Quantity
-- Aggregate units sold across all positive sales transactions
SELECT SUM(CAST(Quantity AS INT)) AS Positive_Quantity
FROM online_retail_raw
WHERE Quantity > 0

-- G. TOTAL Negative Quantity
-- Aggregate units reversed through cancellations and other negative transactions
SELECT SUM(CAST(Quantity AS INT)) AS Negative_Quantity
FROM online_retail_raw
WHERE Quantity < 0

-- =============================================
-- 2. DATA PROFILING
-- Purpose: Assess data quality, identify anomalies,
--          and detect structural issues prior to staging
--			This section informs cleaning governance decisions
-- =============================================

-- A. Row count validation
-- Purpose: Confirm total record volume in raw dataset
SELECT COUNT(*) AS Total_Row_Count
FROM online_retail_raw 

-- B. Null Value Assessment
-- Purpose: Identify missing values across key analytical
--          dimensions that may affect aggregation logic

-- Missing Customer Identifiers
SELECT COUNT(*) AS Count_Null_Customer_ID
FROM online_retail_raw
WHERE Customer_ID is NULL 

-- Missing Product Descriptions
SELECT COUNT(*) AS Count_Null_Description
FROM online_retail_raw
WHERE Description is NULL

-- Missing Unit Price Values
SELECT COUNT(*) AS Count_Null_Price
FROM online_retail_raw
WHERE Price is NULL

-- Missing Quantity 
SELECT COUNT(*) AS Count_Null_Quantity
FROM online_retail_raw
WHERE Quantity is NULL

-- C. Price Integrity Checks

-- Negative Unit Prices
SELECT COUNT(*) AS Negative_Price
FROM online_retail_raw
WHERE Price < 0

-- Price Distribution (Sales Only)
-- Excludes cancellations and negative quantities
-- to assess active selling price behavior
SELECT MIN(Price) AS Min_Price, 
       MAX(Price) AS Max_Price, 
	   AVG(Price) AS AVG_Price
FROM online_retail_raw
WHERE Invoice NOT LIKE 'C%' AND Quantity > 0 AND PRICE > 0

-- High-Value Price Inspection
-- Manual review of highest-priced transactions.

SELECT TOP 10 *
FROM online_retail_raw
WHERE Invoice NOT LIKE 'C%' AND Quantity > 0 AND PRICE > 0
ORDER BY Price DESC

-- D. QUANTITY CHECKS
-- Purpose: Analyze volume behavior including
--          zero, negative, and non-cancellation reversals

-- Zero Quantity Transactions
SELECT COUNT(*) AS Zero_Quantity
FROM online_retail_raw
WHERE Quantity = 0

-- Total Negative Quantity Transactions
SELECT COUNT(*) AS Negative_Quantity
FROM online_retail_raw
WHERE Quantity < 0

-- Negative Quantities Excluding Cancellations
-- Identifies Operational Adjustments
SELECT COUNT(*) AS Negative_Quantity_Excluding_Cancellations
FROM online_retail_raw
WHERE Quantity < 0 AND Invoice NOT LIKE 'C%'

-- E. Cancellation Identification
-- Purpose: Quantify cancellation activity based on
--           invoice prefix convention (C%)
SELECT COUNT(*) AS Cancellations
FROM online_retail_raw
WHERE Invoice LIKE 'C%'

-- F. Duplicate Detection
-- Purpose: Identify exact duplicate transactional records
--          based on full business key equivalence
WITH CTE_Duplicate_Rows AS (
SELECT *, ROW_NUMBER() OVER(
          PARTITION BY Invoice, 
		               StockCode,
					   Description,
					   Quantity,
					   InvoiceDate,
					   Price,
					   Customer_ID,
					   Country
		  ORDER BY InvoiceDate DESC
) AS row_count
FROM online_retail_raw)

SELECT * 
FROM CTE_Duplicate_Rows
WHERE row_count > 1

-- G. Data Type Validation
-- Purpose: Confirm InvoiceDate datatype to ensure
--          compatibility with date-based analytics
SELECT COLUMN_NAME, 
       DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'online_retail_raw'
 AND  COLUMN_NAME = 'InvoiceDate';

-- H. Non-Commercial / Financial Adjustment Analysis
-- Purpose: Identify accounting-related transaction types
--          that do not represent customer purchasing activity

--Non-numeric StockCodes (Potential Adjustment Codes)
SELECT Distinct StockCode 
FROM online_retail_raw
WHERE StockCode NOT LIKE '%[0-9]%' 

-- Manual Entries (M)
SELECT COUNT(*) AS Manual_Count
FROM online_retail_raw
WHERE StockCode = 'M'

SELECT Country, SUM(Quantity * Price) AS RevenueByCountry
FROM online_retail_raw 
WHERE StockCode = 'M'
GROUP BY Country 
ORDER BY RevenueByCountry ASC

SELECT SUM(Quantity * Price) AS TotalRevenue
FROM online_retail_raw
WHERE StockCode = 'M'

-- Adjustment Entries (Adjust / Adjust2)
SELECT COUNT(*) AS Adjust_Count
FROM online_retail_raw
WHERE StockCode IN ('ADJUST', 'ADJUST2')

SELECT Country, SUM(Quantity * Price) AS RevenueByCountry
FROM online_retail_raw	
WHERE StockCode IN ('ADJUST', 'ADJUST2')
GROUP BY Country
ORDER BY RevenueByCountry DESC

SELECT SUM(Quantity * Price) AS TotalRevenue
FROM online_retail_raw 
WHERE StockCode IN ('ADJUST', 'ADJUST2')

-- Bad Debt (B)	
SELECT COUNT(*) AS BadDedt_Count
FROM online_retail_raw
WHERE StockCode = 'B' AND StockCode NOT LIKE '%[0-9]%'

SELECT Country, SUM(Quantity * Price) AS RevenueByCountry
FROM online_retail_raw
WHERE StockCode = 'B' AND StockCode NOT LIKE '%[0-9]%'
GROUP BY Country

SELECT SUM(Quantity * Price) AS TotalRevenue
FROM online_retail_raw
WHERE StockCode = 'B' AND StockCode NOT LIKE '%[0-9]%'

-- Bank Charges
SELECT COUNT(*) AS BankCharges_Count
FROM online_retail_raw
WHERE StockCode = 'BANK CHARGES'

SELECT Country, SUM(Quantity * Price) AS RevenueByCountry
FROM online_retail_raw
WHERE StockCode = 'BANK CHARGES'
GROUP BY Country 
ORDER BY RevenueByCountry ASC

SELECT SUM(Quantity * Price) AS TotalRevenue
FROM online_retail_raw
WHERE StockCode = 'BANK CHARGES'

-- Amazon Platform Fees
SELECT COUNT(*) AS AmazonFee_Count
FROM online_retail_raw
WHERE StockCode = 'AMAZONFEE'

SELECT Country, SUM(Quantity * Price) AS RevenuePerCountry
FROM online_retail_raw
WHERE StockCode = 'AMAZONFEE'
GROUP BY Country

SELECT SUM(Quantity * Price) AS TotalRevenue
FROM online_retail_raw
WHERE StockCode = 'AMAZONFEE'

-- CRUK Commission
SELECT COUNT(*) AS CRUK_Count
FROM online_retail_raw
WHERE StockCode = 'CRUK'

SELECT Country, SUM(Quantity * Price) AS RevenueByCountry
FROM online_retail_raw
WHERE StockCode = 'CRUK'
GROUP BY Country

SELECT SUM(Quantity * Price) AS TotalRevenue
FROM online_retail_raw
WHERE StockCode = 'CRUK'


/* Analysis of non-numeric StockCodes identified several transaction types representing 
   accounting and financial adjustments rather than customer-driven sales activity. 
   These include:
-Manual entries (M)
-Adjustment entries (ADJUST, ADJUST2)
-Bad debt (B)
-Bank charges
-Amazon platform fees
-CRUK commission

-These transactions:
-Do not represent product purchases.
-Do not reflect customer demand or marketing performance.
-Materially distort revenue (largest absolute impacts observed in AMAZONFEE, Bad Debt, and Manual entries).
-Are primarily concentrated in the United Kingdom.
-Given the project objective of identifying top international markets based on commercial performance, 
 these transaction types will be excluded from the staging table to ensure that revenue reflects customer purchasing behavior only.
-Raw data remains preserved in online_retail_raw for audit traceability. */

-- =============================================
-- 3. CLEANING RULEBOOK
-- =============================================

-- Objective:
-- The staging table (online_retail_stg) represents validated commercial 
-- transactions reflecting customer-driven purchasing behavior and is 
-- optimized for revenue, country, customer, and product-level analytics.


-- Removal Policy:
-- 1. Remove transactions with Price <= 0
--    Reason: Non-commercial or invalid pricing.

-- 2. Remove negative quantity transactions excluding cancellations.
--    Reason: Operational inventory adjustments (damaged/missing stock).

-- 3. Remove accounting/financial adjustment StockCodes:
--    ('M', 'ADJUST', 'ADJUST2', 'B', 'BANK CHARGES', 'AMAZONFEE', 'CRUK')
--    Reason: These represent internal financial movements,
--    not customer purchasing activity.

-- 4. Remove exact duplicate records.
--    Reason: Prevent revenue inflation and ensure transactional uniqueness.
--    Exact duplicates defined as identical values across:
--    Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer_ID, Country.


-- Preservation Policy:
-- 1. Preserve cancellation invoices (Invoice LIKE 'C%').
--    These represent legitimate customer refunds and are
--    required for accurate net revenue calculation.

-- 2. Preserve NULL Customer_ID values.
--    These represent anonymous or unregistered customers.

-- Derived Fields (To Be Added in Staging):
-- line_revenue = Quantity * Price
-- is_cancellation (1/0 flag)
-- invoice_year
-- invoice_month
-- invoice_year_month

-- Revenue Definitions:
-- Gross Revenue: Sum of positive Quantity * Price
-- Refund Value: Sum of cancellation transactions
-- Net Revenue: Sum of all transactional revenue including sales and cancellations.

-- Data Lineage:
-- The online_retail_raw table remains unmodified.
-- All transformations are implemented in this script
-- to ensure full reproducibility and audit traceability.

-- =============================================
-- 4. CREATE STAGING TABLE
-- =============================================
DROP TABLE IF EXISTS online_retail_stg;

WITH CTE_CleanedTransactions AS (
SELECT Invoice,
	   StockCode,
	   Description,
	   Quantity,
	   InvoiceDate, 
	   Price,
	   Customer_ID,
	   Country,
	   Quantity * Price AS line_revenue, 
	   YEAR(InvoiceDate) AS invoice_year, 
	   MONTH(InvoiceDate) AS invoice_month,
	   CONVERT(char(7), InvoiceDate, 120) as invoice_year_month,
	   CASE
		   WHEN Invoice LIKE 'C%' THEN 1
		   ELSE 0
	   END AS is_cancellation,
	    ROW_NUMBER() OVER(
          PARTITION BY Invoice,
		              StockCode,
					  Description,
					  Quantity,
					  InvoiceDate,
					  Price,
					  Customer_ID,
					  Country	
		 ORDER BY InvoiceDate
) AS row_num
FROM online_retail_raw
WHERE (Invoice LIKE 'C%'
      OR (Price > 0 AND Quantity > 0)
	  )
	  AND StockCode NOT IN ('M', 'ADJUST', 'ADJUST2', 'B', 'BANK CHARGES', 'AMAZONFEE', 'CRUK')
)

SELECT Invoice,
       StockCode,
       Description,
       Quantity,
       InvoiceDate,
       Price,
       Customer_ID,
       Country,
       line_revenue,
       invoice_year,
       invoice_month,
       invoice_year_month,
       is_cancellation
INTO online_retail_stg
FROM CTE_CleanedTransactions
WHERE row_num = 1

-- =============================================
-- 5. VALIDATION CHECKS
-- =============================================

-- Row Count Comparison
SELECT 
	(SELECT COUNT(*) FROM online_retail_raw) AS raw_row_count,
	(SELECT COUNT(*) FROM online_retail_stg) AS stg_row_count,
	(SELECT COUNT(*) FROM online_retail_raw) - (SELECT COUNT(*) FROM online_retail_stg) AS row_count_difference

-- Revenue Comparison
SELECT 'RAW' AS dataset,
       SUM(CASE WHEN Invoice LIKE 'C%' THEN  Quantity * Price ELSE 0 END) AS refund,
	   SUM(CASE WHEN Quantity > 0 AND Price > 0 THEN Quantity * Price ELSE 0 END) AS gross,
	   SUM (Quantity * Price) AS net
FROM online_retail_raw
UNION ALL
SELECT 'STAGING' AS dataset,
		SUM(CASE WHEN Invoice LIKE 'C%' THEN Quantity * Price ELSE 0 END) AS refund,
		SUM(CASE WHEN Quantity > 0 THEN Quantity * Price ELSE 0 END) AS gross,
		SUM (Quantity * Price) AS net
FROM online_retail_stg

--Adjustment Code Verification
SELECT *
FROM online_retail_stg
WHERE StockCode IN ('M', 'ADJUST', 'ADJUST2', 'B', 'BANK CHARGES', 'AMAZONFEE', 'CRUK')

--Operational Adjustment Verification
SELECT *
FROM online_retail_stg
WHERE Quantity < 0 AND Invoice NOT LIKE 'C%'

--Duplicate Verfication
WITH CTE_Duplcate_Check AS (
SELECT Invoice,
	   StockCode,
	   Description,
	   Quantity,
	   InvoiceDate,
	   Price,
	   Customer_ID,
	   Country,
	   ROW_NUMBER() OVER (
	   PARTITION BY Invoice,
					StockCode,
					Description,
					Quantity,
					InvoiceDate,
					Price,
					Customer_ID,
					Country
	  ORDER BY InvoiceDate) AS row_num 
FROM online_retail_stg
)

SELECT * 
FROM CTE_Duplcate_Check
WHERE row_num > 1