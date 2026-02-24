-- =============================================
-- File: 03_analytical_views.sql
-- Purpose: Clean raw retail data and create staging table
-- =============================================

--Calculate Total Revenue Excluding Cancellations
CREATE VIEW vw_net_revenue_summary AS (
SELECT SUM(CASE 
               WHEN is_cancellation = 0 THEN line_revenue 
               ELSE 0 
           END) as gross_revenue,
       SUM(line_revenue) AS net_revenue,
       SUM(CASE 
               WHEN is_cancellation = 1 THEN ABS(line_revenue)
               ELSE 0
           END) AS refund_amount,
       SUM(CASE 
               WHEN is_cancellation = 1 THEN ABS(line_revenue) 
               ELSE 0 
           END) 
       / 
       NULLIF(SUM(CASE 
               WHEN is_cancellation = 0 THEN (line_revenue) 
               ELSE 0 
           END),0) * 100 AS refund_rate_pct,
       COUNT(DISTINCT CASE 
                          WHEN is_cancellation = 0 
                          THEN Invoice 
                      END) as total_orders,
       COUNT(DISTINCT CASE 
                          WHEN is_cancellation = 1 
                          THEN Invoice 
                      END) as total_cancelled_orders,
       SUM(CASE 
               WHEN is_cancellation = 0 
               THEN CAST(Quantity AS INT) 
               ELSE 0 
           END) AS total_quantity_sold
FROM online_retail_stg
)

CREATE VIEW vw_country_revenue_summary AS(
SELECT Country,
       SUM(line_revenue)AS total_revenue,
       SUM(CAST(Quantity AS INT)) AS total_quantity,
       COUNT(DISTINCT Invoice) AS total_orders,
       COUNT(DISTINCT Customer_ID) AS unique_customers,
       SUM(line_revenue) * 1.0 / COUNT(DISTINCT Invoice) AS avg_order_value,
       SUM(line_revenue) * 1.0 / NULLIF(COUNT(DISTINCT Customer_ID), 0)AS revenue_per_customer,
       SUM(CAST(Quantity AS INT))  * 1.0 / COUNT(DISTINCT Invoice) AS avg_quantity_per_order, 
       SUM(line_revenue) * 1.0 / SUM(SUM(line_revenue)) OVER() * 100 AS revenue_pct_of_total
FROM online_retail_stg
WHERE is_cancellation = 0 AND Country <> 'United Kingdom' 
GROUP BY Country
)

CREATE VIEW vw_customer_ranking AS (
SELECT Customer_ID,
       Country,
       SUM(line_revenue) AS total_spend,
       COUNT(DISTINCT Invoice) AS total_orders,
       SUM(line_revenue) * 1.0 / COUNT(DISTINCT Invoice) AS avg_order_value,
       SUM(CAST(Quantity AS INT)) AS total_quantity,
       SUM(line_revenue) * 1.0 / SUM(SUM(line_revenue)) OVER() * 100 AS revenue_pct_of_total,
       DENSE_RANK() OVER (ORDER BY SUM(line_revenue) DESC) AS customer_rank 
FROM online_retail_stg
WHERE is_cancellation = 0 
      AND Customer_ID is NOT NULL 
      AND COUNTRY <> 'United Kingdom'
GROUP BY Customer_ID, Country
)

CREATE VIEW vw_country_product_performance AS(
SELECT Country,
       StockCode,
       Description,
       SUM(CAST(Quantity AS INT)) as total_quantity,
       SUM(line_revenue) AS total_revenue,
       COUNT(DISTINCT Invoice) AS total_orders
FROM online_retail_stg
WHERE is_cancellation = 0
      AND Country <> 'United Kingdom'
      AND StockCode 
      NOT IN ('POST', 'DOT', 'PADS', 'SAMPLES', 'D', 'GIFT')
GROUP BY Country, 
         StockCode, 
         Description
)

CREATE VIEW vw_country_monthly_trends AS (
SELECT Country,
       YEAR(InvoiceDate) AS year,
       MONTH(InvoiceDate) AS month,
       invoice_year_month,
       SUM(line_revenue) AS monthly_revenue,
       COUNT(DISTINCT Invoice) AS monthly_orders,
       COUNT(DISTINCT Customer_ID)  AS monthly_customers,
       SUM(line_revenue) * 1.0 / NULLIF(COUNT(DISTINCT Invoice),0) AS monthly_avg_order_value,
       SUM(SUM(line_revenue)) OVER (
                              PARTITION BY Country
                              ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate)
                              ) AS cumulative_revenue
FROM online_retail_stg
WHERE is_cancellation = 0 
      AND Country <> 'United Kingdom'
GROUP BY Country, 
         YEAR(InvoiceDate), 
         MONTH(InvoiceDate), 
         invoice_year_month
)

CREATE VIEW vw_country_cancellation_impact AS(
SELECT Country, 
       COUNT(DISTINCT CASE 
                          WHEN is_cancellation = 0 
                          THEN Invoice 
                       END) AS total_orders,
       COUNT(DISTINCT CASE 
                          WHEN is_cancellation = 1 
                          THEN Invoice 
                       END) AS cancelled_orders,
      COUNT(DISTINCT CASE WHEN is_cancellation = 1 THEN Invoice END) * 1.0 
      /
      NULLIF(COUNT(DISTINCT Invoice), 0) * 100 AS cancellation_rate_pct,
      SUM(CASE 
                  WHEN is_cancellation = 1 
                  THEN ABS(line_revenue) 
                  ELSE 0
          END) AS cancelled_revenue,
      SUM(CASE 
                  WHEN is_cancellation = 1 
                  THEN ABS(line_revenue)
                  ELSE 0
          END) 
      / 
      NULLIF(SUM(CASE 
                  WHEN is_cancellation = 0 
                  THEN line_revenue
                  ELSE 0
          END),0) * 100 AS cancellation_revenue_pct
FROM online_retail_stg
WHERE Country <> 'United Kingdom'
GROUP BY Country
)

