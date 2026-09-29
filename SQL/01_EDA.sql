/************************************************************************************************************************************************
FIRST PART - EXPLORATORY DATA ANALYSIS (EDA)
-- The first part consists of an Exploratory Data Analysis (EDA) to understand the dataset, the business structure, and identify
-- initial insights regarding sales performance and trends.
-- Note: 
************************************************************************************************************************************************/

-- =====================================================
-- DATA SOURCE
-- =====================================================
-- The original dataset was created by  https://www.datawithbaraa.com
-- The dataset used for this analysis is hosted in Google BigQuery.
-- Project and dataset identifiers have been anonymized for portfolio publication purposes.

-- Replace PROJECT_ID.DATASET_NAME with the corresponding BigQuery project and dataset in your environment.
-- =====================================================


-- ===========================================================================================================================================
--FIRST STEP: Data overview
-- ===========================================================================================================================================
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM `PROJECT_ID.DATASET_NAME.INFORMATION_SCHEMA.COLUMNS`
ORDER BY table_name
;
-- The dataset consists of three tables:
-- fact_sales: transactional sales data
-- dim_customers: customer attributes
-- dim_products: product attributes


-- ===========================================================================================================================================
-- SECOND STEP: Product analysis
-- ===========================================================================================================================================

-- Products by Category and Subcategory
SELECT 
DISTINCT category, 
subcategory,
product_name
FROM `PROJECT_ID.DATASET_NAME.dim_products`
WHERE category IS NOT NULL
ORDER BY 1, 2, 3
;

-- Number of Categories, Subcategories, and Products
SELECT
    COUNT(DISTINCT category) AS number_of_categories,
    COUNT(DISTINCT subcategory) AS number_of_subcategories,
    COUNT(DISTINCT product_name) AS number_of_products
FROM `PROJECT_ID.DATASET_NAME.dim_products`
;

-- There are a total of 295 products across 4 categories and 36 subcategories.
SELECT 
DISTINCT category, 
subcategory,
product_name
FROM `PROJECT_ID.DATASET_NAME.dim_products`
WHERE category IS NULL
ORDER BY 1, 2, 3
;
-- Data quality check:
-- 7 products have missing category and subcategory values.
-- All identified products are pedals.

-- Analyzing the Average Product Cost by Category
SELECT
    category,
    ROUND(AVG(cost), 2) AS Average_cost
FROM `PROJECT_ID.DATASET_NAME.dim_products`
GROUP BY category 
ORDER BY 2 DESC
;
-- Bicycles have the highest average product cost, followed by components.

-- ===========================================================================================================================================
-- THIRD STEP: Customer Analysis
-- ===========================================================================================================================================

SELECT  
  COUNT(DISTINCT customer_id) AS Total_customers,
FROM `PROJECT_ID.DATASET_NAME.dim_customers`
;
-- The business registers a total of 18,484 unique customers.

SELECT  
  COUNT(DISTINCT customer_id) AS Total_customers,
  gender
FROM `PROJECT_ID.DATASET_NAME.dim_customers`
GROUP BY gender
ORDER BY Total_customers DESC
;
-- The customer distribution by gender is practically 50 - 50

SELECT  
  COUNT(DISTINCT customer_id) AS Total_customers,
  country
FROM `PROJECT_ID.DATASET_NAME.dim_customers`
GROUP BY country
ORDER BY Total_customers DESC
;
-- The United States has the largest number of customers (7,482), followed by Australia (3,591) and, to a lesser extent, the United Kingdom, France, Germany, and Canada. In addition, 337 customers do not specify their country of origin in their information.

-- Age range of our customers:
SELECT
  APPROX_QUANTILES(age,100)[OFFSET(1)] AS MIN,
  APPROX_QUANTILES(age,100)[OFFSET(25)] AS P25,
  APPROX_QUANTILES(age,100)[OFFSET(50)] AS Median,
  APPROX_QUANTILES(age,100)[OFFSET(75)] AS P75,
  APPROX_QUANTILES(age,100)[OFFSET(90)] AS P90,
  APPROX_QUANTILES(age,100)[OFFSET(95)] AS P95,
  APPROX_QUANTILES(age,100)[OFFSET(100)] AS MAX
FROM (
SELECT
DATE_DIFF('2014-1-31', birthdate, YEAR) AS age
FROM `PROJECT_ID.DATASET_NAME.dim_customers`
)
;

WITH age_group AS (
SELECT
  customer_id,
  country,
  gender,
  DATE_DIFF('2014-1-31', birthdate, YEAR) AS age,
  CASE 
    WHEN DATE_DIFF('2014-1-31', birthdate, YEAR) BETWEEN 28 AND 39 THEN '28-39'
    WHEN DATE_DIFF('2014-1-31', birthdate, YEAR) BETWEEN 40 AND 59 THEN '40-59'
    WHEN DATE_DIFF('2014-1-31', birthdate, YEAR) BETWEEN 60 AND 69 THEN '60-69'
    ELSE '70 or more'
  END AS age_range
FROM `PROJECT_ID.DATASET_NAME.dim_customers`
)

SELECT
  COUNT(customer_id)  AS total_customers,
  ROUND(COUNT(customer_id)/SUM(COUNT(customer_id)) OVER() * 100, 2) AS percentage,
  age_range
FROM age_group
GROUP BY age_range
ORDER BY COUNT(customer_id) DESC
;
-- Our youngest customer is 28 years old, while our oldest customer is 98.
-- 48.65% of our customers are between 40 and 59 years old, while 37.83% are young adults (28–39 years old).

-- ===========================================================================================================================================
-- FOURTH STEP: Exploring the Sales Table (fact_sales)
-- ===========================================================================================================================================

-- Calculating the main business metrics at an aggregate level.

SELECT 'Total_sales' AS Measure_name, SUM(sales_amount) AS Measure_value FROM `PROJECT_ID.DATASET_NAME.fact_sales`
UNION ALL
SELECT 'Total_items_sold' AS Measure_name,SUM(quantity) AS Measure_value FROM `PROJECT_ID.DATASET_NAME.fact_sales`
UNION ALL
SELECT 'AVG_price' AS Measure_name, AVG(price) AS Measure_value FROM `PROJECT_ID.DATASET_NAME.fact_sales`
UNION ALL
SELECT 'Total_orders' AS Measure_name, COUNT(DISTINCT order_number) AS Measure_value FROM `PROJECT_ID.DATASET_NAME.fact_sales`
UNION ALL
SELECT 'Total_products' AS Measure_name, COUNT(DISTINCT product_id) AS Measure_value FROM `PROJECT_ID.DATASET_NAME.dim_products`
UNION ALL
SELECT 'Total_customers' AS Measure_name,COUNT(DISTINCT customer_id) AS Measure_value FROM `PROJECT_ID.DATASET_NAME.dim_customers`
UNION ALL
SELECT 'Total_customers_with_orders' AS Measure_name, COUNT(DISTINCT customer_key) AS Measure_value FROM `PROJECT_ID.DATASET_NAME.fact_sales`
;

-- A total of 60,423 products have been sold for a total revenue of USD 29,356,250 throughout the business's history.
-- All registered customers have made at least one purchase, and all products have been sold at least once.
-- The average price is USD 486, although this can vary significantly across product categories.



-- Analyzing each product category's contribution to total business sales.
WITH sales_by_category AS (
    SELECT
        p.category,
        SUM(s.sales_amount) AS total_revenue,
        SUM(s.quantity) AS total_units
    FROM `PROJECT_ID.DATASET_NAME.fact_sales` AS s
    LEFT JOIN `PROJECT_ID.DATASET_NAME.dim_products` AS p
        ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY p.category
)

SELECT 
    category,
    total_revenue,
    SUM(total_revenue) OVER() AS overall_revenue,
    ROUND(
        total_revenue / SUM(total_revenue) OVER() * 100,
        2
    ) AS revenue_percentage
FROM sales_by_category
ORDER BY total_revenue DESC
;
-- Our main source of revenue comes from bicycle sales, followed by accessories and, in third place, clothing.


-- Analyzing Sales Trends

-- Monthly Sales
SELECT
  DATE_TRUNC(fact_sales.order_date, MONTH) AS sales_month,
  SUM(fact_sales.sales_amount) AS total_sales_amount,
  SUM(fact_sales.quantity) AS total_quantity_sold,
  COUNT(DISTINCT fact_sales.customer_key) AS total_customers
FROM `PROJECT_ID.DATASET_NAME`.`fact_sales` AS fact_sales
WHERE DATE_TRUNC(fact_sales.order_date, MONTH) IS NOT NULL
GROUP BY sales_month
ORDER BY sales_month
;

-- Annual Sales
SELECT
  EXTRACT(YEAR FROM fact_sales.order_date) AS Year,
  DATE_TRUNC(fact_sales.order_date, YEAR) AS sales_year,
  SUM(fact_sales.sales_amount) AS total_sales_amount,
  SUM(fact_sales.quantity) AS total_quantity_sold,
  COUNT(DISTINCT fact_sales.customer_key) AS total_customers
FROM `PROJECT_ID.DATASET_NAME`.`fact_sales` AS fact_sales
WHERE DATE_TRUNC(fact_sales.order_date, YEAR) IS NOT NULL
GROUP BY sales_year, Year
ORDER BY sales_year, Year
;

-- Looking for Seasonal Patterns
SELECT
  EXTRACT(MONTH FROM fact_sales.order_date) AS Month_number,
  FORMAT_DATETIME('%B', fact_sales.order_date) AS Month,
  SUM(fact_sales.sales_amount) AS total_sales_amount,
  SUM(fact_sales.quantity) AS total_quantity_sold,
  COUNT(DISTINCT fact_sales.customer_key) AS total_customers
FROM `PROJECT_ID.DATASET_NAME.fact_sales` AS fact_sales
WHERE DATE_TRUNC(fact_sales.order_date, YEAR) IS NOT NULL
GROUP BY Month_number, Month
ORDER BY Month_number
;

-- Sales by categories - Annual evoluton
WITH sales_by_category_year AS(
SELECT
  EXTRACT(YEAR FROM s.order_date) AS Year,
  p.category,
  SUM(s.sales_amount) AS total_sales_amount,
  SUM(s.quantity) AS total_quantity_sold
FROM `PROJECT_ID.DATASET_NAME.fact_sales` AS s
LEFT JOIN PROJECT_ID.DATASET_NAME.dim_products AS p
ON s.product_key = p.product_key
WHERE s.order_date IS NOT NULL
GROUP BY Year, category
ORDER BY Year, category
)

SELECT 
  Year,
  category,
  total_sales_amount,
  SUM(total_sales_amount) OVER(PARTITION BY Year) AS total_sales_year,
  ROUND((total_sales_amount/SUM(total_sales_amount) OVER(PARTITION BY Year))*100, 2) AS percentage
FROM sales_by_category_year
ORDER BY Year, category
;

-- The business began operations in December 2010, with 14 customers, 14 items sold, and total revenue of USD 43,419.
-- 2013 represents a major expansion phase, with a substantial increase in both customer acquisition and sales volume compared with previous years.
-- In January 2014, there were 834 customers, 1,970 products sold, and total revenue of USD 45,642.
-- June is one of the peak sales months. Sales then show an upward trend again from October through December.
-- Accessories and clothing were introduced in 2012. Although both categories expanded in 2013, bicycles remained the dominant revenue source, accounting for approximately 94% of annual sales.

-- ===========================================================================================================================================
-- KEY FINDINGS FROM THE EXPLORATORY DATA ANALYSIS
-- ===========================================================================================================================================

/*
1. Business scale
   - 60,423 units sold for total revenue of USD 29.36M.
   - The dataset covers 38 months, from December 2010 to January 2014.

2. Business growth
   - 2013 was the main expansion year, with a substantial increase in both customer base and sales volume.

3. Product portfolio
   - 295 products across 4 categories and 36 subcategories.
   - Bicycles are the dominant source of revenue.

4. Customer base
   - 18,484 registered customers across 6 countries.
   - The United States and Australia account for the largest customer bases.

5. Customer demographics
   - Customer ages range from 28 to 98.
   - Approximately 85% of customers are between 28 and 59 years old.

6. Seasonality
   - Sales activity shows recurring monthly patterns, with stronger performance around June and during the October–December period.
*/