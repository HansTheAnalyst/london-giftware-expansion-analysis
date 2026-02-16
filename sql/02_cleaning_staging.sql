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
SELECT SUM(Quantity * Price) as Gross_Revenue
FROM online_retail_raw 
WHERE Quantity > 0

-- B. Refund Value
-- Total value of customer cancellations. Identified by cancellation invoices (Invoice LIKE 'C%') and negative quantity.
SELECT SUM(Quantity * Price) as Refund_Value
FROM online_retail_raw
WHERE Invoice LIKE 'C%' AND Quantity < 0

-- C. Net Revenue 
-- Total transactional revenue including both sales and cancellations.
SELECT SUM(Quantity * Price) as Net_Revenue
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

SELECT Country, SUM(Quantity * Price) RevenueByCountry
FROM online_retail_raw	
WHERE StockCode IN ('ADJUST', 'ADJUST2')
GROUP BY Country
ORDER BY RevenueByCountry DESC

SELECT SUM(Quantity * Price) AS TotalRevenue
FROM online_retail_raw 
WHERE StockCode IN ('ADJUST', 'ADJUST2')

-- Bad Debt (B)	
SELECT COUNT(*) as BadDedt_Count
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
-- 3. CLEANING RULEBOOK (Comment Section)
-- =============================================

-- =============================================
-- 4. CREATE STAGING TABLE
-- =============================================

-- =============================================
-- 5. VALIDATION CHECKS
-- =============================================