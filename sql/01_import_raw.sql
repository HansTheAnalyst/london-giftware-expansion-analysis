--=================================
--File: 01_import_raw.sql
--Purpose: Document raw data ingestion
--Source: Kaggle - Online Retail II UCI
--Method: SSMS Import Flat File
--=================================

--Rows must be 1,067,371
SELECT COUNT(*)
FROM online_retail_raw

SELECT TOP(10) *
FROM online_retail_raw