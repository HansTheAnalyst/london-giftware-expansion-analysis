# International Market Expansion Analysis - London Giftware Co.
![SQL](https://img.shields.io/badge/SQL-Data%20Processing-blue)
![Excel](https://img.shields.io/badge/Excel-Validation-green)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-yellow)
![Tableau](https://img.shields.io/badge/Tableau-Visualization-orange)
![Git](https://img.shields.io/badge/Git-Version%20Control-black)

## Project Overview

London Giftware Co. is an international wholesale retailer specializing in decorative giftware
products. The company sells primarily through bulk wholesale orders to international buyers.

Currently, the company only monitors **total revenue**, which limits its ability to make
strategic decisions regarding international market expansion. They lack visibility into:

- The financial impact of refunds and cancellations
- Which international markets drive the most revenue
- Their highest value customers
- Product demand patterns across countries

This project builds a **structured analytics solution** that transforms raw transactional data
into actionable business insights using **SQL**, **Excel validation**, **Tableau Visualization**, and **Power BI Dashboard**.

The objective is to identify the **Top 3 most profitable international markets (excluding the united kingdom)**
that the company should prioritize for next year's marketing expansion strategy.

### Disclaimer

This project is a simulated business scenario created for portfolio and educational purposes.
The analysis uses the publicly available **Online Retail dataset** and does not represent
the actual operations or financial data of a real company.
The objective of this project is to demonstrate a professional end to end data analytics workflow,
including data auditing, SQL transformation, Excel validation, Tableau visualization, and Power BI dashboard developmennt.

---
## Power BI Dashboard 

## Live Interactive Tableau Dashboard

Explore the interactive dashboard on Tableau Public:
https://public.tableau.com/app/profile/hans.justin.fernando/viz/LondonGiftwareExpansionAnalysis/LondonGiftwareMarketExpansionAnalysis

---

## Business Objective

Identify the **Top 3 most profitable international markets (excluding the UK)** to guide next year's
marketing investment strategy.

The analysis answers four critical business questions:

### 1. The Refund Trap

What is the **true revenue** afer accounting for cancellations and refunds?

### 2. International Powerhouses

Which **countries generate the highest net revenue** outside the United Kingdom?

### 3. The Whale Hunt

Who are the **highest value customers driving the majority of revenue**?

### 4. Product Affinity

Which **products dominate demand in the top international markets**?

---

## Dataset

## Online Retail II UCI

A real online transactional data set of two years.

This Online Retail II data set contains all the transactions occurring for a UK-based and registered,
non-store online retail between 01/12/2009 and 09/12/2011.The company mainly sells unique all-occasion gift-ware.
Many customers of the company are wholesalers.
https://www.kaggle.com/datasets/mashlyn/online-retail-ii-uci

Key characteristics:
- 1 million transactional rows
- International wholesale orders
- Product level transaction data
- Refund and cancellation orders
- Customer purchase history

Main fields include:
- Invoice
- StockCode
- Description
- Quantity
- InvoiceDate
- Price
- Customer_ID
- Country

Cleaned dataset are not stored in this repository due to Github file size limits.

---

## Professional Technical Workflow

This project follow a **layered ELT (Extract-Load-Transform) architecture**, which mirrors real-world
analytic practices used in modern data teams.

## Layer 1 - Ingestion Layer

File: 01_import_raw.sql

Purpose:
- Import the CSV dataset
- Load the raw data into SQL Server
- Create the online_retail_raw table

No transformation occurs here. This layer preserves the original source data exactly as received.

## Layer 2 - Staging Layer

File: 02_cleaning_staging.sql

Purpose:
- Audit raw data
- Remove operational noise
- Preserve valid financial transactions
- Create derived analytical fields

Cleaning rules applied:

Removed:

- UnitPrice ≤ 0
- Inventory adjustment rows
- Exact duplicate transactions

Kept:

- Refund and cancellation transactions (flagged for analysis)
- NULL CustomerID values (valid anonymous transactions)

Derived fields created:

- line_revenue
- is_cancellation
- invoice_year
- invoice_month
- invoice_day

The resulting table becomes the clean transactional dataset used for analytics.

## Layer 3 — Analytical Layer

File:

03_analytical_views.sql

This layer produces **business intelligence metrics** through SQL views.

Views include:

- Net revenue calculations
- Country revenue rankings
- Customer revenue rankings
- Basket size metrics
- Product popularity metrics

These analytical views serve as the **data source for Excel validation and Tableau dashboards**.

---

## Data Audit

Initial profiling of the raw dataset revealed several data quality issues.

| Data Issue            |     Count |
| --------------------- | --------: |
| Total Rows            | 1,067,371 |
| NULL Customer IDs     |   243,007 |
| Cancellations         |    19,494 |
| Inventory Adjustments |     3,457 |
| Negative Prices       |     6,207 |
| Duplicate Groups      |    32,907 |

These issues were addressed during the staging layer cleaning process to ensure financial accuracy.

---

## Excel Validation

Excel was used to **validate the SQL outputs**, ensuring analytical accuracy and reconciliation.

Excel validation checks included:

- Revenue totals reconciliation
- Top country ranking verification
- Customer revenue validation
- Basket size recalculation
- Refund distribution checks

This step mirrors professional environments where **finance and marketing teams rely heavily on Excel for verification and reporting**.

The validation process ensures **cross-tool consistency between SQL calculations and Excel results**.

---

## Tableau Dashboards

Tableau was used to transform the analytical outputs into **executive-level visual insights**.

The dashboard provides an interactive overview of international market performance, customer value, and product demand.

Explore the interactive dashboard:

https://public.tableau.com/app/profile/hans.justin.fernando/viz/LondonGiftwareExpansionAnalysis/LondonGiftwareMarketExpansionAnalysis

## Dashboard Components

### Executive Overview

High-level business performance indicators:

- Net Revenue
- Gross Revenue
- Refund Loss
- Refund Rate

### International Market Analysis

Identifies the most profitable international markets.

Visualizations include:

- Top Countries by Net Revenue
- Country Revenue Share
- Global Revenue Map

These insights help determine where expansion marketing should be focused.

### Customer Insights

Analyzes high-value customer behavior.

Visualizations include:

- Top Customers by Revenue
- Revenue Concentration Analysis
- Orders vs Spend Relationship

This highlights the impact of wholesale buyers who generate a significant portion of revenue.

### Product Insights

Examines product demand patterns.

Visualizations include:

- Top Products by Quantity Sold
- Quantity vs Revenue Comparison

These charts reveal which products drive the majority of international demand.

---

## Key Findings

### Top International Markets

The three most profitable international markets (excluding the UK) are:

1. Ireland (EIRE)
2. Netherlands
3. Germany

These markets generate the highest net revenue and represent the strongest candidates for marketing expansion.

### Customer Revenue Concentration

Revenue is highly concentrated among a small number of wholesale buyers.

The **top 20 customers generate approximately 58% of total revenue**, indicating strong reliance on high-value customers.

### Refund Impact

Refunds account for approximately **3.7% of gross revenue**, highlighting the importance
of distinguishing between gross and net sales when measuring business performance.

### Product Demand

Demand is concentrated around vintage-style decorative giftware, including mugs, night lights,
and paint sets, which dominate international product sales.

---

## Tools Used

- SQL Server
- Excel
- Tableau
- Git & GitHub

---

## Skills Demonstrated

This project demonstrates several core data analyst competencies:

- Data auditing and profiling
- SQL data cleaning and transformation
- Analytical SQL view design
- Revenue analytics and business metrics
- Excel reconciliation and validation
- Tableau dashboard development
- Business insight communication
- Professional analytics workflow
