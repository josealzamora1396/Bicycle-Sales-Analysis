/************************************************************************************************************************************************
SECOND PART - IN-DEPTH CUSTOMER ANALYSIS
=================================================================================================================================================

OBJECTIVE
---------
This section performs an in-depth analysis of the customer base to understand customer
characteristics, purchasing behavior, spending levels, and activity status.

The analysis combines demographic, geographic, spending, and recency information to
identify meaningful customer segments and evaluate their contribution to overall sales.

The resulting customer-level view will also serve as the foundation for further analysis
and for building a Business Intelligence dashboard.

BUSINESS QUESTIONS
------------------
1. Who are our customers, and how are they distributed across countries and age groups?
2. How much does the average customer spend, and how does spending vary across customer segments?
3. Which customer segments generate the largest share of total revenue?
4. Which countries and age groups have the highest customer value?
5. How does customer activity vary across different spending levels?
6. What proportion of high-value customers is currently active, new, or inactive?
7. Are there customer segments that may represent opportunities for retention or re-engagement?

CUSTOMER SEGMENTATION FRAMEWORK
-------------------------------
Customers will be segmented using two complementary dimensions:

1. CUSTOMER ACTIVITY (RECENCY)
   - New Client: The customer's first purchase was made within the last 12 months.
   - Active Client: The customer has made a purchase within the last 12 months.
   - Inactive Client: The customer has not made a purchase within the last 12 months.

2. CUSTOMER SPENDING LEVEL
   - Regular Client: Average monthly spending below USD 500.
   - High-Value Client: Average monthly spending between USD 500 and USD 1,500.
   - VIP Client: Average monthly spending above USD 1,500.

The spending thresholds are established after examining the distribution of customer-level
average monthly spending.

************************************************************************************************************************************************/


/************************************************************************************************************************************************
1. ESTABLISHING CUSTOMER SPENDING THRESHOLDS
=================================================================================================================================================

Before creating the customer segmentation, we first examine the distribution of average
monthly customer spending.

This step helps determine reasonable thresholds for distinguishing Regular, High-Value,
and VIP customers based on the observed distribution of spending.
************************************************************************************************************************************************/

-- First, we need to establish the thresholds for each category.
-- To do this, we will examine the distribution of our customers' average monthly spending.
WITH customer_details AS (
SELECT
  c.customer_key,
  c.first_name,
  c.last_name,
  c.country,
  c.gender,
  c.birthdate,
  MIN(f.order_date) as first_order_date,
  MAX(f.order_date) as last_order_date,
-- We will calculate the customers' activity period in days and months.
  DATE_DIFF(MAX(f.order_date), MIN(f.order_date), DAY) AS lifespan_days,
  ROUND(DATE_DIFF(MAX(f.order_date), MIN(f.order_date), DAY)/30,2) AS lifespan_months,
  SUM(f.quantity) AS total_quantity,
  SUM(f.sales_amount) AS total_sales,
  SUM(IF(EXTRACT(YEAR FROM order_date) = 2013, f.sales_amount, 0)) AS total_sales_2013,
  SUM(IF(EXTRACT(YEAR FROM order_date) = 2014, f.sales_amount, 0)) AS total_sales_2014,
-- Calculation of customers' average monthly spending
  CASE
    WHEN ROUND(DATE_DIFF(MAX(f.order_date), MIN(f.order_date), DAY)/30,2) < 1 THEN SUM(f.sales_amount)
    ELSE ROUND(SUM(f.sales_amount)/ROUND(DATE_DIFF(MAX(f.order_date), MIN(f.order_date), DAY)/30,2),2)
  END AS monthly_sales
FROM PROJECT_ID.DATASET_NAME.fact_sales f
LEFT JOIN PROJECT_ID.DATASET_NAME.dim_customers c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name, c.country, c.gender, c.birthdate, c.create_date
ORDER BY customer_key
)

-- Using the previous table, we will calculate metrics on the distribution of average monthly spending.
SELECT
  AVG(monthly_sales) AS avg_monthly_sales,
  VARIANCE(monthly_sales) AS var_monthly_sales,
  STDDEV(monthly_sales) AS std_monthly_sales,
  MIN(monthly_sales) AS min_monthly_sales,
  MAX(monthly_sales) AS max_monthly_sales,
  100 * STDDEV(monthly_sales)/AVG(monthly_sales) AS Coef_Var,
  APPROX_QUANTILES(monthly_sales,100)[OFFSET(25)] AS P25,  
  APPROX_QUANTILES(monthly_sales,100)[OFFSET(50)] AS P50,
  APPROX_QUANTILES(monthly_sales,100)[OFFSET(75)] AS P75,
  APPROX_QUANTILES(monthly_sales,100)[OFFSET(90)] AS P90,
  APPROX_QUANTILES(monthly_sales,100)[OFFSET(95)] AS P95
FROM customer_details
;

-- Based on the observed distribution of average monthly spending,
-- we decided to set the category thresholds in increments of USD 500.
-- Therefore, for segmentation purposes, we will use the following categories:
-- below USD 500, between USD 500 and USD 1,500, and above USD 1,500.


/************************************************************************************************************************************************
2. CREATING THE CUSTOMER SEGMENTATION VIEW
=================================================================================================================================================

Having established the segmentation framework, we create a customer-level view containing
the main demographic, purchasing, spending, and activity metrics.

This view will consolidate the information required for subsequent customer analysis
and dashboard development.
************************************************************************************************************************************************/

-- Having confirmed the rules, we will proceed to create the View with the customer segmentation.
CREATE OR REPLACE VIEW `portfolio-projects-494203.baraa_sales_analysis.customer_segmentation` AS
WITH customer_details AS (
SELECT
  c.customer_key,
  c.customer_id,
  c.first_name,
  c.last_name,
  c.country,
  c.gender,
  c.birthdate,
  MIN(f.order_date) as first_order_date,
  MAX(f.order_date) as last_order_date,
  DATE_DIFF(MAX(f.order_date), MIN(f.order_date), DAY) AS lifespan_days,
  ROUND(DATE_DIFF(MAX(f.order_date), MIN(f.order_date), DAY)/30,2) AS lifespan_months,
  COUNT(DISTINCT order_number) AS total_orders,
  SUM(f.quantity) AS total_quantity,
  SUM(f.sales_amount) AS total_sales,
  SUM(IF(EXTRACT(YEAR FROM order_date) = 2013, f.sales_amount, 0)) AS total_sales_2013,
  SUM(IF(EXTRACT(YEAR FROM order_date) = 2014, f.sales_amount, 0)) AS total_sales_2014,
  CASE
    WHEN ROUND(DATE_DIFF(MAX(f.order_date), MIN(f.order_date), DAY)/30,2) < 1 THEN SUM(f.sales_amount)
    ELSE ROUND(SUM(f.sales_amount)/ROUND(DATE_DIFF(MAX(f.order_date), MIN(f.order_date), DAY)/30,2),2)
  END AS monthly_sales
FROM PROJECT_ID.DATASET_NAME.fact_sales f
LEFT JOIN PROJECT_ID.DATASET_NAME.dim_customers c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.customer_id, c.first_name, c.last_name, c.country, c.gender, c.birthdate, c.create_date
ORDER BY customer_key
)

SELECT 
  CONCAT(first_name, ' ', last_name) AS full_name,
  customer_id,
  country,
  gender,
  birthdate,
-- Age Segmentation
  CASE 
    WHEN DATE_DIFF('2014-01-31', birthdate, YEAR) < 18 THEN 'Minor'
    WHEN DATE_DIFF('2014-01-31', birthdate, YEAR) BETWEEN 18 AND 29 THEN 'Young Adult (18 - 29)'
    WHEN DATE_DIFF('2014-01-31', birthdate, YEAR) BETWEEN 30 AND 39 THEN 'Adult (30s)'
    WHEN DATE_DIFF('2014-01-31', birthdate, YEAR) BETWEEN 40 AND 49 THEN 'Adult (40s)'
    WHEN DATE_DIFF('2014-01-31', birthdate, YEAR) BETWEEN 50 AND 59 THEN 'Adult (50s)'
    WHEN DATE_DIFF('2014-01-31', birthdate, YEAR) > 59 THEN 'Senior (60 or more)'
  END AS Age_group,
  lifespan_months,
  total_quantity,
  total_orders,
  total_sales,
-- Average Order Value (AOV)
  ROUND(total_sales / total_orders, 2) AS avg_ticket,
  monthly_sales,
-- Customer Type by Spending Level
  CASE
    WHEN monthly_sales < 500 THEN 'Regular Client'
    WHEN monthly_sales BETWEEN 500 AND 1000 THEN 'High Value Client'
    ELSE 'VIP Client'
  END AS Expense_level,
-- Customer Type by Activity (Recency)
CASE
    WHEN first_order_date >= DATE_SUB(DATE '2014-01-28', INTERVAL 12 MONTH)
      THEN 'New Client'
    WHEN last_order_date >= DATE_SUB(DATE '2014-01-28', INTERVAL 12 MONTH)
      THEN 'Active Client'
    ELSE 'Inactive Client'
  END AS Recency_level,
FROM customer_details
;


/************************************************************************************************************************************************
3. VALIDATING THE CUSTOMER SEGMENTATION VIEW
=================================================================================================================================================
************************************************************************************************************************************************/

-- Testing the View
SELECT *
FROM `PROJECT_ID.DATASET_NAME.customer_segmentation`
;


/************************************************************************************************************************************************
4. CUSTOMER PERFORMANCE BY COUNTRY
=================================================================================================================================================

This analysis evaluates customer performance across countries to identify differences in
customer base size, purchasing volume, revenue generation, and customer value.

Key questions:
- Which countries have the largest customer bases?
- Which countries generate the most revenue?
- Which markets have the highest average order value and monthly spending?
************************************************************************************************************************************************/

-- Performance per country
SELECT 
  country,
  COUNT(*) AS total_customers,
  SUM(total_quantity) AS total_quantity,
  SUM(total_sales) AS total_sales,
  ROUND(AVG(avg_ticket), 2) AS avg_ticket,
  ROUND(AVG(monthly_sales), 2) AS avg_monthly_sales
FROM `PROJECT_ID.DATASET_NAME.customer_segmentation`
GROUP BY country
ORDER BY total_sales DESC
;

-- The United States has the largest number of customers, but it does not have the highest average order value, being surpassed by Australia and Canada.
-- With less than half the number of customers in the United States, Australia has generated almost the same sales volume, with the highest average order value among all countries.
-- Australian customers may be more likely to purchase higher-end products.


/************************************************************************************************************************************************
5. CUSTOMER PERFORMANCE BY AGE GROUP
=================================================================================================================================================

This analysis examines how customer demographics relate to purchasing behavior and revenue
generation.

Key questions:
- Which age groups represent the largest share of the customer base?
- Which age groups generate the most revenue?
- How does average order value and monthly spending vary across age groups?
************************************************************************************************************************************************/

-- Analyzing Age Groups
SELECT 
  age_group,
  COUNT(*) AS total_customers,
  ROUND(COUNT(*)/(SELECT COUNT(*) FROM `PROJECT_ID.DATASET_NAME.customer_segmentation`)*100, 2) AS percentage_customers,
  SUM(total_quantity) AS total_quantity,
  SUM(total_sales) AS total_sales,
  ROUND(SUM(total_sales)/(SELECT SUM(total_sales) FROM `PROJECT_ID.DATASET_NAME.customer_segmentation`)*100, 2) AS percentage_sales,
  ROUND(AVG(avg_ticket), 2) AS avg_ticket,
  ROUND(AVG(monthly_sales), 2) AS avg_monthly_sales
FROM `PROJECT_ID.DATASET_NAME.customer_segmentation`
GROUP BY age_group
ORDER BY total_customers DESC
;

-- 85% of our customers are adults between 30 and 59 years old, with average monthly spending close to USD 500.
-- 35% of our customers are adults in their 30s, with average monthly spending of USD 466.29.
-- The share of young adults (18–29) is relatively small (3.31%). Along with senior adults, they have the lowest average monthly spending.


/************************************************************************************************************************************************
6. CUSTOMER DISTRIBUTION BY SPENDING LEVEL
=================================================================================================================================================

Customers are grouped according to their average monthly spending to understand the
distribution of customer value and its contribution to overall revenue.

Key questions:
- What proportion of customers belongs to each spending segment?
- What share of revenue is generated by each segment?
- How does average order value vary across spending levels?
************************************************************************************************************************************************/

-- Customer Distribution by Spending Level
SELECT 
  Expense_level,
  COUNT(*) AS total_customers,
  ROUND(COUNT(*)/(SELECT COUNT(*) FROM `PROJECT_ID.DATASET_NAME.customer_segmentation`)*100, 2) AS Total_customer_percentage,
  SUM(total_quantity) AS total_quantity,
  SUM(total_sales) AS total_sales,
  ROUND(SUM(total_sales)/(SELECT SUM(total_sales) FROM `PROJECT_ID.DATASET_NAME.customer_segmentation`)*100, 2) AS total_sales_percentage,
  ROUND(AVG(avg_ticket), 2) AS avg_ticket,
  ROUND(AVG(monthly_sales), 2) AS avg_monthly_sales
FROM `PROJECT_ID.DATASET_NAME.customer_segmentation`
GROUP BY Expense_level
ORDER BY total_sales DESC
;

-- 75% of our customers fall into the Regular category (monthly spending below USD 500) and account for 71% of our sales, with average monthly spending of USD 116.89.
-- 15% of our customers are VIPs (monthly spending above USD 1,500) and account for 20% of our sales, with average monthly spending of USD 2,027.


/************************************************************************************************************************************************
7. CUSTOMER ACTIVITY BY SPENDING LEVEL
=================================================================================================================================================

This analysis combines spending level and customer recency to evaluate the activity status
of each customer segment.

Key questions:
- What proportion of each spending segment is currently active?
- Which spending segments have the highest proportion of inactive customers?
- How significant is the share of new customers within each spending segment?
- Are high-value customer segments showing signs of inactivity?
************************************************************************************************************************************************/

-- Evaluating Customer Activity Status by Spending Level
SELECT 
  Expense_level,
  COUNT(Expense_level) AS total_clients,
  COUNT(CASE WHEN Recency_level = 'Inactive Client' THEN Expense_level END) AS Inactive_Client,
  ROUND(COUNT(CASE WHEN Recency_level = 'Inactive Client' THEN Expense_level END)/COUNT(Expense_level)*100, 2) AS Percentage_Inactive,
  COUNT(CASE WHEN Recency_level = 'Active Client' THEN Expense_level END) AS Active_Client,
  ROUND(COUNT(CASE WHEN Recency_level = 'Active Client' THEN Expense_level END)/COUNT(Expense_level)*100, 2) AS Percentage_Active,
  COUNT(CASE WHEN Recency_level = 'New Client' THEN Expense_level END) AS New_Client,
  ROUND(COUNT(CASE WHEN Recency_level = 'New Client' THEN Expense_level END)/COUNT(Expense_level)*100, 2) AS Percentage_New
FROM `PROJECT_ID.DATASET_NAME.customer_segmentation`
GROUP BY Expense_level
ORDER BY Inactive_Client DESC
;

-- 47% of our VIP customers are new, having made a purchase within the last year; however, 23% of our VIP customers are inactive.
-- Similarly, 47% of our High-Value customers are new, while 8.7% are inactive.
-- Only 2.47% of our Regular customers are inactive.


/************************************************************************************************************************************************
8. KEY INSIGHTS FROM CUSTOMER ANALYSIS
=================================================================================================================================================
************************************************************************************************************************************************/

/* 
1. Customer demographics
   - 85% of customers are adults between 30 and 59 years old. They account for 82% of sales
     and have the highest average monthly spending compared with the youngest and oldest age groups.

2. Geographic performance
   - Although the United States has the largest number of customers, Canada and Australia
     have higher average order values and higher average monthly spending.

3. Customer value by country
   - Australia, with half as many customers, has generated almost the same sales volume as
     the United States and has the highest average order value.
   - Incentives could be introduced to increase purchase frequency, especially for
     specialized high-end equipment.

4. Customer retention
   - A significant percentage of VIP customers are inactive (23%), suggesting an opportunity
     for targeted re-engagement campaigns.
*/

/************************************************************************************************************************************************
9. RECOMENDED ACTIONS
=================================================================================================================================================
************************************************************************************************************************************************/

/*
1. Launch targeted re-engagement campaigns for inactive high-value customers.
    - Identify inactive VIP customers and develop personalized offers, product
        recommendations, and early-access promotions to encourage repeat purchases.

2. Develop strategies to increase customer value in high-potential markets.
    - Australia and Canada show relatively higher customer spending levels.
    - Further analyze purchase frequency and product preferences in these markets
        to identify opportunities for customer acquisition and higher-value sales.

3. Prioritize retention and cross-selling among customers aged 30–59.
    - This segment represents the majority of the customer base and generates
        most of the company's revenue. Focus on retention, cross-selling, and
        personalized product recommendations while developing strategies to
        increase engagement among younger customers.
*/