# Bicycle Sales Analysis

## Overview
This project analyzes historical sales data from a bicycle company to understand business performance, customer behavior, and product performance.

The analysis combines **SQL in Google BigQuery** and **Power BI** to transform transactional data into business insights and interactive visualizations.

The project focuses on three main analytical areas:

- Business Performance: Revenue, sales volume, category and subcategory performance, and sales evolution over time.
- Customer Analysis: Customer activity, demographics, spending behavior, and market reach.
- Product Performance: Revenue, profitability, product concentration, market penetration, YoY growth, and products with and without recorded sales.


## Business Problem

The objective of this project is to analyze historical sales data and identify the main factors driving revenue, profitability, customer engagement, and product performance.

The analysis addresses the following business questions:

**Business Performance**
- How has revenue evolved over time?
- Which product categories and subcategories generate the most revenue?
- How concentrated is revenue across the product portfolio?

**Customer Performance**
- Who are the company's customers?
- Which customer groups generate the most revenue?
- How many customers are active, inactive, or new?
- How broadly does each product category reach the customer base?

**Product Performance**
- Which products generate the most revenue and profit?
- Which products contribute most to the company's revenue?
- How concentrated is revenue among the top-performing products?
- Which products have the highest market penetration?
- How has product performance changed over time?


## Dataset

The dataset contains historical sales transactions together with customer and product information.

The database consists of three main tables:

- **fact_sales:** Transaction-level sales data.
- **dim_customers:** Customer information and demographic attributes.
- **dim_products:** Product information, categories, subcategories, and costs.

The dataset covers approximately 38 months of business activity, from December 2010 to January 2014.

### Dataset Overview

- **18,484** customers
- **295** products in the product catalog
- **60,423** units sold
- **$29.36M** in historical revenue
- **4** product categories
- **36** subcategories

**Note:** The product catalog contains 295 products. Only 130 of these products have recorded sales in the historical transaction data. The analysis intentionally retains all 295 products to identify products with no recorded sales.


## Tools & Technologies

- **SQL:** Google BigQuery
- **Data Visualization:** Microsoft Power BI
- **Data Analysis:** SQL, DAX
- **Development Environment:** Visual Studio Code


## Metodology

The analysis was divided into three main stages.

**1. Exploratory Data Analysis**

The first stage focused on understanding the structure and characteristics of the dataset.

The analysis included:

- Dataset structure and validation
- Customer and product counts
- Revenue and sales volume
- Category and subcategory performance
- Annual and monthly sales trends
- Customer demographics
- Product-level sales performance

View [Exploratory Data Analysis](<../SQL/Exploratory Data Analysis.sql>) in SQL



**2. Customer Segmentation**

The second stage focused on understanding customer behavior and identifying differences in customer activity and value.

The analysis included:

- Customer activity status
- Recency
- New vs. existing customers
- Customer spending
- Average ticket
- Monthly spending
- Age groups
- Country-level performance
- Customer segmentation

The customer activity analysis uses a fixed reference date of January 31, 2014 to reproduce the historical analysis consistently.

View [Customer Segmentation](<../SQL/Customer segmentation.sql>) in SQL


**3. Product Performance**

The third stage focused on evaluating the company's product portfolio from multiple perspectives.

The analysis included:

- Revenue and units sold
- Profit and profit margin
- Revenue ranking
- Category and subcategory ranking
- Revenue contribution
- Cumulative revenue
- Pareto analysis
- Market penetration
- Year-over-Year growth
- Historical ranking evolution
- Products with and without recorded sales

View [Product Performance Analysis](<../SQL/Product performance analysis.sql>) in SQL

## SQL Analysis

The analysis was developed in **Google BigQuery** using SQL.

### Customer Segmentation

Customer-level metrics were calculated from transaction data, including first and last purchase dates, total orders, total units purchased, total sales, customer lifespan, and average monthly spending.

The analysis then classified customers according to **Age group, recency and spending behavior**.

For the complete analysis, view [Customer Segmentation](<../SQL/Customer segmentation.sql>)

**Age Group segmentation:**
```sql
  CASE 
    WHEN DATE_DIFF('2014-01-31', birthdate, YEAR) < 18 THEN 'Minor'
    WHEN DATE_DIFF('2014-01-31', birthdate, YEAR) BETWEEN 18 AND 29 THEN 'Young Adult (18 - 29)'
    WHEN DATE_DIFF('2014-01-31', birthdate, YEAR) BETWEEN 30 AND 39 THEN 'Adult (30s)'
    WHEN DATE_DIFF('2014-01-31', birthdate, YEAR) BETWEEN 40 AND 49 THEN 'Adult (40s)'
    WHEN DATE_DIFF('2014-01-31', birthdate, YEAR) BETWEEN 50 AND 59 THEN 'Adult (50s)'
    WHEN DATE_DIFF('2014-01-31', birthdate, YEAR) > 59 THEN 'Senior (60 or more)'
  END AS Age_group,
```

**Segmentation by Recency:**
```sql
CASE
    WHEN first_order_date >= DATE_SUB(DATE '2014-01-28', INTERVAL 12 MONTH)
      THEN 'New Client'
    WHEN last_order_date >= DATE_SUB(DATE '2014-01-28', INTERVAL 12 MONTH)
      THEN 'Active Client'
    ELSE 'Inactive Client'
  END AS Recency_level,
```

**Segmentation by Speding Behavior:**
```sql
  CASE
    WHEN monthly_sales < 500 THEN 'Regular Client'
    WHEN monthly_sales BETWEEN 500 AND 1000 THEN 'High Value Client'
    ELSE 'VIP Client'
  END AS Expense_level,
```


### Product Performance

Product-level analysis was built from the complete product catalog using a `LEFT JOIN` with sales transactions. This approach ensured that products with no recorded sales were retained in the analysis.

For the complete analysis, view [Product Performance Analysis](<../SQL/Product performance analysis.sql>)


```sql
FROM dim_products AS p

LEFT JOIN fact_sales AS s
    ON p.product_key = s.product_key
```

The analysis calculated metrics such as:

* Total revenue
* Units sold
* Average selling price
* Margin
* Market penetration
* Revenue ranking
* Category-level revenue comparison
* Cumulative revenue for Pareto analysis

#### Key Metrics:

**Percentage revenue:**
```sql
    SUM(
        COALESCE(SUM(s.sales_amount), 0)
    ) OVER() AS overall_total_revenue,
    ROUND(
        SAFE_DIVIDE(
            COALESCE(SUM(s.sales_amount), 0),
            SUM(COALESCE(SUM(s.sales_amount), 0)) OVER()
        ) * 100,
        4
    ) AS percentage_rev,
```
**Ranking Revenue:**
```sql
    RANK() OVER(
        ORDER BY COALESCE(SUM(s.sales_amount), 0) DESC
    ) AS revenue_rank,
```

**Average Revenue of the corresponding Category:**
```sql

    -- Average revenue within each category
    ROUND(
        AVG(product_sales.total_revenue)
            OVER(PARTITION BY category),
        2
    ) AS avg_revenue_category,
```

**Product Performance vs. Category:**
```sql
    CASE
        WHEN product_sales.total_revenue >
             ROUND(
                 AVG(product_sales.total_revenue)
                 OVER(PARTITION BY category),
                 2
             )
            THEN 'Above Average'
        WHEN product_sales.total_revenue <
             ROUND(
                 AVG(product_sales.total_revenue)
                 OVER(PARTITION BY category),
                 2
             )
            THEN 'Below Average'
        ELSE 'Equal to Average'
    END AS Sales_Performance_vs_avg
```

**Market Penetration:**
```sql
    ROUND(
      SAFE_DIVIDE(
        COUNT(DISTINCT s.customer_key),
        MAX(c.total_customers)
      ) * 100,
       2
    ) AS market_penetration
```

**Pareto Analysis**

Window functions were used to rank products and calculate their cumulative contribution to total revenue.

```sql
    -- Cumulative revenue
    SUM(product_sales.total_revenue) OVER(
        ORDER BY product_sales.total_revenue DESC
    ) AS cum_revenue,

    -- Cumulative revenue percentage
    ROUND(
        SUM(percentage_rev) OVER(
            ORDER BY product_sales.total_revenue DESC
        ),
        2
    ) AS cum_percentage_rev,
```

This allowed the analysis to identify the number of products responsible for approximately **80% and 90% of total revenue**.

The complete SQL queries are available in the [SQL](../SQL) folder.


## Key Business Insights

### Customer Insights

1. **Customer base is highly concentrated among adults aged 30–59.**
   Approximately **85% of customers are between 30 and 59 years old**, accounting for around **82% of total sales**. Customers in their 30s represent the largest age group, at approximately **35% of the customer base**, with an average monthly spending of **$466.29**.

2. **Most customers are Regular customers, while a smaller high-value segment contributes disproportionately to revenue.**
   Approximately **75% of customers are classified as Regular Customers**, generating around **71% of total sales**, with average monthly spending of **$116.89**. In contrast, approximately **15% are classified as VIP Customers**, accounting for around **20% of sales**, with average monthly spending of approximately **$2,027**.

3. **Customer activity varies significantly across spending segments.**
   Approximately **47% of VIP Customers are classified as New Customers**, while **23% are Inactive**. Among High-Value Customers, approximately **47% are New Customers and 8.7% are Inactive**. In comparison, only around **2.47% of Regular Customers are Inactive**. This indicates that customer inactivity is not evenly distributed across spending segments.

4. **Customer value differs substantially across countries, even when customer volume is lower.**
   The **United States has the largest customer base and the highest overall sales volume**. However, customers in **Australia and Canada show higher Average Order Values (AOV) and average monthly spending**. Australia, in particular, has fewer than half as many customers as the United States while generating a comparable level of sales, resulting in the highest AOV among the analyzed countries.

5. **Accessories reach a much broader customer base despite their smaller contribution to revenue.**
   **Bicycles generate 96.46% of total revenue** but are purchased by approximately **49% of customers**. Accessories, in contrast, account for only around **3.76% of revenue** while reaching approximately **82% of customers**. This highlights a substantial difference between product reach and revenue contribution.

### Product Performance Insights

1. **Revenue is highly concentrated among a relatively small number of products.**
   The **top 35 products generate approximately 80.84% of total revenue**, while the top 50 account for around **90.26%**. The remaining **245 products contribute only 9.74% of total revenue**, indicating a highly concentrated product revenue distribution which is particulary concentated in bikes

2. **A significant portion of the product catalog has no recorded sales.**
   The catalog contains **295 products**, of which **130 have recorded sales and 165 have no recorded sales** during the analyzed period. The presence of products without sales should be considered in the context of product lifecycle, availability, assortment strategy, or other business factors that are not directly observable in the dataset. Between the products with no registered sales, 127 of this are Components. This category registers no sales in the analyzed period.

3. **Bicycles dominate revenue generation, particularly Road Bikes and Mountain Bikes.**
   Bicycles account for **96.46% of total revenue**, with **Road Bikes and Mountain Bikes together generating approximately 85% of total revenue**. Accessories have significantly broader customer penetration but contribute only a small share of overall revenue.

4. **The highest-revenue products combine strong sales concentration with relatively high margins.**
   The **top 10 products account for approximately 42.49% of total revenue**. These products are all bicycles and generally show margins in the range of approximately **39%–44%**, indicating that the products driving the largest share of revenue also generate substantial gross margins. 

5. **Accessories have broad customer reach despite their smaller revenue contribution.**
    Bicycles generated approximately **96.46% of revenue**, but only around **49% of customers** purchased bicycles during the analyzed period. In comparison, approximately **82% of customers** purchased accessories. Accessories therefore reach a much broader portion of the customer base despite representing only approximately **3.76% of total revenue**. This creates an opportunity to investigate cross-selling and accessory purchasing behavior.


## Business Considerations

Based on the analysis, several business considerations emerge:

* **Focus on high-value products:** Revenue is heavily concentrated among a relatively small number of products. Monitoring the availability, profitability, and sales trends of these products should be a priority.

* **Review products with no recorded sales:** A significant portion of the catalog generated no revenue during the analyzed period. Further analysis could help determine whether these products are discontinued, newly introduced, inactive, unavailable, or simply underperforming.

* **Monitor customer retention among high-value segments:** VIP and High-Value customers generate a disproportionately large share of revenue, but a relevant portion of these customers is classified as inactive. Retention and reactivation strategies could therefore be particularly relevant for these segments.

* **Differentiate strategies by customer profile:** Customer value varies considerably across spending segments, age groups, and countries. A single customer strategy may therefore not be equally effective across the entire customer base.

* **Consider both customer reach and revenue contribution:** Accessories reach a much larger proportion of customers than bicycles, despite contributing a relatively small share of revenue. This difference could be considered when evaluating cross-selling and product portfolio strategies.

* **Monitor product performance over time:** Cumulative revenue alone may hide changes in product momentum. Year-over-year performance and recent sales activity provide additional context for identifying products gaining or losing relevance.

---

## Power BI Dashboard

The SQL analysis was transformed into an interactive Power BI dashboard designed to provide an executive overview of business performance, customer behavior, and product performance.

### Customer Analysis

![alt text](<../Images/Customer and Sales Dashboard.JPG>)

The customer analysis provides visibility into:

- Customer activity
- Customer demographics
- Revenue contribution by age group
- Customer spending behavior
- Customer reach by product category
- Customer segmentation

### Product Performance

![alt text](<../Images/Product performance Dashboard.JPG>)

The product performance analysis focuses on:

- Revenue contribution by category
- Product-level Pareto analysis
- Revenue vs. profitability
- Market penetration
- Product performance over time
- Other Key metrics

---

## Key DAX Measures

The Power BI dashboard uses DAX measures to calculate key performance indicators dynamically.

### Total Revenue

```DAX
Total Revenue =
SUM(Sales[sales_amount])
```

### Products with Sales

```DAX
Products with Sales =
CALCULATE(
    DISTINCTCOUNT(product_analysis[product_key]),
    product_analysis[total_revenue] > 0
)
```

### Products without Sales

```DAX
Products without Sales =
CALCULATE(
    DISTINCTCOUNT(product_analysis[product_key]),
    product_analysis[total_revenue] = 0
)
```

### Total Clients

```DAX
Total Clients =
DISTINCTCOUNT(Clients[customer_id])
```

### Active Clients %

```DAX
Active Clients % =
DIVIDE(
    [Active Clients],
    [Total Clients],
    0
)
```

### Average Ticket

```DAX
Average Ticket =
DIVIDE(
    SUM(Sales[sales_amount]),
    SUM(Sales[quantity]),
    0
)
```

Additional measures used to support the dashboard are available in the [Dax Key Measures](../DAX/DAX_Key_Measures.md) file.

---

## Project Structure

```text
Bicycle-Sales-Analysis/
│
├── README.md
│
├── SQL/
│   ├── 01_EDA.sql
│   ├── 02_Customer_Segmentation.sql
│   └── 03_Product_Performance.sql
│
├── DAX/
│   └── Key_Measures.md
│
├── PowerBI/
│   └── Bicycle_Sales_Dashboard.pbix
│
└── Images/
    ├── customer_analysis.png
    └── product_performance.png
```

---

## Data Availability Note

The analysis was originally conducted using a Google BigQuery dataset.

For portfolio publication purposes, the original project and dataset identifiers have been anonymized. The SQL scripts retain the original table structure and analytical logic, but the underlying dataset is not included in this repository.

To reproduce the analysis, the anonymized project and dataset references can be replaced with equivalent tables in another BigQuery environment.

---

## Skills Demonstrated

This project demonstrates the following analytical and technical skills:

* **SQL:** Data exploration, joins, aggregations, window functions, CTEs, conditional logic, date calculations, ranking, and analytical views.
* **BigQuery:** Query development and analytical data preparation in a cloud data warehouse environment.
* **Customer Analytics:** Customer segmentation based on recency, spending behavior, demographics, geography, and activity.
* **Product Analytics:** Revenue analysis, product ranking, Pareto analysis, market penetration, margin analysis, and year-over-year performance.
* **Power BI:** Interactive dashboard development, KPI design, data visualization, and business-oriented reporting.
* **DAX:** Dynamic measures, KPI calculations, filtering, ranking, and analytical metrics.
* **Data Visualization:** Executive-oriented presentation of business performance and key findings.
* **Business Analysis:** Translating quantitative analysis into actionable business considerations.

