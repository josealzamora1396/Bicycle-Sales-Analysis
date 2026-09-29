/************************************************************************************************************************************************
Third PART - PRODUCT PERFORMANCE ANALYSIS
=================================================================================================================================================

/*** PRODUCT ANALYSIS ***/

-- In this section, we analyze which products and categories generate the highest revenue
-- and profit, how their performance has evolved over time, and the types of customers
-- they attract.
--
-- Business questions:
-- 1. Which categories and subcategories generate the most revenue and profit?
-- 2. Which individual products contribute the most to total revenue?
-- 3. How concentrated is revenue across the product portfolio?
-- 4. Which products have the highest and lowest revenue?
-- 5. Which products perform best within each category?
-- 6. Which products have the highest customer market penetration?
-- 7. How has product performance changed over time?
-- 8. Which products show sustained growth, decline, or changes in their relative ranking?



/************************************************************************************************************************************************
1. CATEGORY PERFORMANCE
************************************************************************************************************************************************/
*/

-- Business question:
-- Which product categories generate the most revenue, profit, and customer reach?


SELECT
    category,
    SUM(quantity) AS total_items_sold,
    SUM(sales_amount) AS total_revenue,
    SUM(quantity * cost) AS total_cost,
    SUM(sales_amount) - SUM(quantity * cost) AS profit,
    ROUND(
        SAFE_DIVIDE(
            SUM(sales_amount) - SUM(quantity * cost),
            SUM(sales_amount)
        ),
        2
    ) * 100 AS Margin,
    ROUND(
        SUM(sales_amount) / SUM(SUM(sales_amount)) OVER() * 100,
        2
    ) AS percentage_rev,
    ROUND(
        (SUM(sales_amount) - SUM(quantity * cost))
        / SUM(SUM(sales_amount) - SUM(quantity * cost)) OVER() * 100,
        2
    ) AS percentage_profit,
    COUNT(DISTINCT customer_key) AS total_customers

FROM (
    SELECT
        p.category,
        p.cost,
        s.quantity,
        s.sales_amount,
        s.customer_key
    FROM `portfolio-projects-494203.baraa_sales_analysis.fact_sales` AS s
    LEFT JOIN `portfolio-projects-494203.baraa_sales_analysis.dim_products` AS p
        ON s.product_key = p.product_key
)

GROUP BY category
ORDER BY SUM(sales_amount) DESC
;

-- Key insights:
-- • Bicycles account for 96.46% of total historical revenue, with 15,205 units sold
--   and total revenue of USD 28,316,272.
--
-- • Of the 18,484 customers in the dataset, 9,132 purchased bicycles, while
--   15,114 purchased accessories.
--
-- • Accessories have the highest margin at approximately 63%, despite representing
--   only 3.76% of total revenue.
--
-- • Accessories have broad customer reach: approximately 82% of customers purchased
--   at least one accessory.



/************************************************************************************************************************************************
2. SUBCATEGORY PERFORMANCE
************************************************************************************************************************************************/

-- Business question:
-- Which product subcategories are the main contributors to revenue and profit?

SELECT
    category,
    subcategory,
    SUM(quantity) AS total_items_sold,
    SUM(sales_amount) AS total_revenue,
    SUM(quantity * cost) AS total_cost,
    SUM(sales_amount) - SUM(quantity * cost) AS profit,
    ROUND(
        SAFE_DIVIDE(
            SUM(sales_amount) - SUM(quantity * cost),
            SUM(sales_amount)
        ),
        2
    ) * 100 AS Margin,
    ROUND(
        SUM(sales_amount) / SUM(SUM(sales_amount)) OVER() * 100,
        2
    ) AS percentage_rev,
    ROUND(
        (SUM(sales_amount) - SUM(quantity * cost))
        / SUM(SUM(sales_amount) - SUM(quantity * cost)) OVER() * 100,
        2
    ) AS percentage_profit,
    COUNT(DISTINCT customer_key) AS total_customers

FROM (
    SELECT
        p.category,
        p.subcategory,
        p.cost,
        s.quantity,
        s.sales_amount,
        s.customer_key
    FROM `portfolio-projects-494203.baraa_sales_analysis.fact_sales` AS s
    LEFT JOIN `portfolio-projects-494203.baraa_sales_analysis.dim_products` AS p
        ON s.product_key = p.product_key
)

GROUP BY
    category,
    subcategory

ORDER BY SUM(sales_amount) DESC
;

-- Key insight:
-- • Road Bikes and Mountain Bikes account for approximately 85% of total company revenue,
--   confirming that the business is highly concentrated around bicycle products.



/************************************************************************************************************************************************
3. CREATING THE PRODUCT ANALYSIS VIEW
************************************************************************************************************************************************/

-- The next step is to create a detailed product-level view containing metrics such as
-- units sold, revenue, profit, profitability, customer reach, rankings, and historical
-- revenue by year.
--
-- Unlike the previous version of this view, which contained only the 130 products
-- with recorded sales, this version starts from dim_products and uses a LEFT JOIN
-- with fact_sales.
--
-- As a result, the view contains all 295 products in the product catalog, including
-- the 165 products that did not record any sales during the analysis period.
--
-- This structure allows us to analyze both product performance and products with
-- no recorded sales.



CREATE OR REPLACE VIEW `portfolio-projects-494203.baraa_sales_analysis.product_analysis` AS
WITH product_sales AS (
SELECT
    p.product_key,
    p.product_id,
    p.category,
    p.subcategory,
    p.product_name,

    -- Sales volume
    COALESCE(
        SUM(s.quantity),
        0
    ) AS total_items_sold,

    -- Total revenue
    COALESCE(
        SUM(s.sales_amount),
        0
    ) AS total_revenue,

    -- Revenue by year
    COALESCE(
        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM s.order_date) = 2010
                THEN s.sales_amount
                ELSE 0
            END
        ),
        0
    ) AS revenue_2010,

    COALESCE(
        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM s.order_date) = 2011
                THEN s.sales_amount
                ELSE 0
            END
        ),
        0
    ) AS revenue_2011,

    COALESCE(
        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM s.order_date) = 2012
                THEN s.sales_amount
                ELSE 0
            END
        ),
        0
    ) AS revenue_2012,

    COALESCE(
        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM s.order_date) = 2013
                THEN s.sales_amount
                ELSE 0
            END
        ),
        0
    ) AS revenue_2013,

    COALESCE(
        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM s.order_date) = 2014
                THEN s.sales_amount
                ELSE 0
            END
        ),
        0
    ) AS revenue_2014,

    -- Cost and profit
    COALESCE(
        SUM(s.quantity * p.cost),
        0
    ) AS total_cost,

    COALESCE(
        SUM(s.sales_amount),
        0
    )
    -
    COALESCE(
        SUM(s.quantity * p.cost),
        0
    ) AS profit,

    -- Profit margin
    ROUND(
        SAFE_DIVIDE(
            COALESCE(SUM(s.sales_amount), 0)
            -
            COALESCE(SUM(s.quantity * p.cost), 0),
            COALESCE(SUM(s.sales_amount), 0)
        ),
        2
    ) * 100 AS Margin,

    -- Revenue ranking
    RANK() OVER(
        ORDER BY COALESCE(SUM(s.sales_amount), 0) DESC
    ) AS revenue_rank,

    RANK() OVER(
        PARTITION BY p.category
        ORDER BY COALESCE(SUM(s.sales_amount), 0) DESC
    ) AS category_revenue_rank,

    RANK() OVER(
        PARTITION BY p.subcategory
        ORDER BY COALESCE(SUM(s.sales_amount), 0) DESC
    ) AS subcategory_revenue_rank,

    -- Profit ranking
    RANK() OVER(
        ORDER BY
            COALESCE(SUM(s.sales_amount), 0)
            -
            COALESCE(SUM(s.quantity * p.cost), 0) DESC
    ) AS profit_rank,

    -- Overall revenue
    SUM(
        COALESCE(SUM(s.sales_amount), 0)
    ) OVER() AS overall_total_revenue,

    ROUND(
        SAFE_DIVIDE(
            COALESCE(SUM(s.sales_amount), 0),
            SUM(
                COALESCE(SUM(s.sales_amount), 0)
            ) OVER()
        ) * 100,
        4
    ) AS percentage_rev,

    -- Overall profit
    SUM(
        COALESCE(SUM(s.sales_amount), 0)
        -
        COALESCE(SUM(s.quantity * p.cost), 0)
    ) OVER() AS overall_total_profit,

    ROUND(
        SAFE_DIVIDE(
            COALESCE(SUM(s.sales_amount), 0)
            -
            COALESCE(SUM(s.quantity * p.cost), 0),
            SUM(
                COALESCE(SUM(s.sales_amount), 0)
                -
                COALESCE(SUM(s.quantity * p.cost), 0)
            ) OVER()
        ) * 100,
        4
    ) AS percentage_profit,

    -- Number of customers who purchased each product
    COUNT(DISTINCT s.customer_key) AS customers_buying,

    -- Customer market penetration
    ROUND(
        SAFE_DIVIDE(
            COUNT(DISTINCT s.customer_key),
            MAX(c.total_customers)
        ) * 100,
        2
    ) AS market_penetration

FROM `portfolio-projects-494203.baraa_sales_analysis.dim_products` AS p

LEFT JOIN `portfolio-projects-494203.baraa_sales_analysis.fact_sales` AS s
    ON p.product_key = s.product_key

CROSS JOIN (
    SELECT
        COUNT(DISTINCT customer_id) AS total_customers
    FROM `portfolio-projects-494203.baraa_sales_analysis.dim_customers`
) AS c

GROUP BY
    p.product_key,
    p.product_id,
    p.category,
    p.subcategory,
    p.product_name,
    c.total_customers
)

SELECT
    *,

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

    -- Cumulative profit
    SUM(profit) OVER(
        ORDER BY product_sales.profit DESC
    ) AS cum_profit,

    -- Cumulative profit percentage
    ROUND(
        SUM(percentage_profit) OVER(
            ORDER BY product_sales.profit DESC
        ),
        2
    ) AS cum_percentage_profit,

    -- Revenue per customer
    ROUND(
        SAFE_DIVIDE(
            total_revenue,
            customers_buying
        ),
        2
    ) AS rev_per_customer,

    -- Profit per customer
    ROUND(
        SAFE_DIVIDE(
            profit,
            customers_buying
        ),
        2
    ) AS profit_per_customer,

    -- Average revenue within each category.
    -- Products with no sales are excluded from the average because they do not
    -- represent observed product revenue.
    ROUND(
        AVG(
            CASE
                WHEN product_sales.total_revenue > 0
                THEN product_sales.total_revenue
            END
        ) OVER(PARTITION BY category),
        2
    ) AS avg_revenue_category,

    -- Sales performance compared with the category average
    CASE
        WHEN product_sales.total_revenue >
             ROUND(
                 AVG(
                     CASE
                         WHEN product_sales.total_revenue > 0
                         THEN product_sales.total_revenue
                     END
                 ) OVER(PARTITION BY category),
                 2
             )
            THEN 'Above Average'

        WHEN product_sales.total_revenue <
             ROUND(
                 AVG(
                     CASE
                         WHEN product_sales.total_revenue > 0
                         THEN product_sales.total_revenue
                     END
                 ) OVER(PARTITION BY category),
                 2
             )
            THEN 'Below Average'

        ELSE 'Equal to Average'
    END AS Sales_Performance_vs_avg

FROM product_sales
ORDER BY product_sales.total_revenue DESC
;



/************************************************************************************************************************************************
4. TESTING THE PRODUCT ANALYSIS VIEW
************************************************************************************************************************************************/

-- Testing the final view

SELECT *
FROM `portfolio-projects-494203.baraa_sales_analysis.product_analysis`
;



/************************************************************************************************************************************************
5. PRODUCTS WITH AND WITHOUT SALES
************************************************************************************************************************************************/

-- Business question:
-- How many products in the 295-product catalog have recorded sales?

SELECT
    CASE
        WHEN total_revenue > 0 THEN 'Has Sales'
        ELSE 'No Sales'
    END AS sales_status,
    COUNT(*) AS total_products

FROM `portfolio-projects-494203.baraa_sales_analysis.product_analysis`

GROUP BY sales_status

ORDER BY total_products DESC
;

-- Key insight:
-- • The product catalog contains 295 products.
-- • 130 products recorded sales during the analysis period.
-- • 165 products did not record any sales.



/************************************************************************************************************************************************
6. PRODUCTS WITH NO RECORDED SALES
************************************************************************************************************************************************/

-- Business question:
-- Which products in the catalog did not record any sales during the analysis period?

-- Detailed table by product
SELECT
    product_key,
    product_id,
    product_name,
    category,
    subcategory
FROM `portfolio-projects-494203.baraa_sales_analysis.product_analysis`
WHERE total_revenue = 0
ORDER BY
    category,
    subcategory,
    product_name
;



/************************************************************************************************************************************************
7. PRODUCTS WITHOUT SALES BY CATEGORY
************************************************************************************************************************************************/
-- Business question:
-- Which categories contain the highest number of products with no recorded sales?

SELECT
    category,
    COUNT(*) AS products_without_sales
FROM `portfolio-projects-494203.baraa_sales_analysis.product_analysis`
WHERE total_revenue = 0
GROUP BY category
ORDER BY products_without_sales DESC
;

-- Key insight:
-- • Components account for the largest number of products with no recorded sales, with 127 products in this category.



/************************************************************************************************************************************************
8. PRODUCTS WITHOUT SALES BY SUBCATEGORY
************************************************************************************************************************************************/

-- Business question:
-- Which subcategories contain the highest number of products with no recorded sales?

SELECT
    category,
    subcategory,
    COUNT(*) AS products_without_sales
FROM `portfolio-projects-494203.baraa_sales_analysis.product_analysis`
WHERE total_revenue = 0
GROUP BY
    category,
    subcategory
ORDER BY products_without_sales DESC
;
-- Road Frames, Mountain Frames and Touring frames account for 79 of the total products with no recorded sales



/************************************************************************************************************************************************
9. PRODUCT REVENUE AND PROFIT PERFORMANCE
************************************************************************************************************************************************/

-- Business question:
-- Which products generate the most revenue and profit?

SELECT 
    product_name,
    category,
    subcategory,
    total_items_sold,
    total_revenue,
    revenue_rank,
    cum_percentage_rev,
    profit,
    profit_rank,
    Margin

FROM `portfolio-projects-494203.baraa_sales_analysis.product_analysis`
ORDER BY total_revenue DESC
LIMIT 10
;

-- Key insights:
-- • The top 10 products by historical revenue are all bicycles, consisting of
--   mountain and road bikes.
--
-- • These 10 products collectively generate 42.49% of total company revenue,
--   highlighting a high degree of revenue concentration at the product level.
--
-- • These products are also among the company's most profitable products.
--
-- • Their margins range approximately from 39% to 44%.



/************************************************************************************************************************************************
10. PARETO ANALYSIS
************************************************************************************************************************************************/

-- Business question:
-- How concentrated is total revenue across the 295-product catalog?
--
-- Bicycles already account for more than 97% of revenue. The next step is to determine
-- how many individual products are responsible for the majority of total revenue.

SELECT 
    product_name,
    category,
    subcategory,
    total_items_sold,
    total_revenue,
    revenue_rank,
    percentage_rev,
    cum_percentage_rev
FROM `portfolio-projects-494203.baraa_sales_analysis.product_analysis`
ORDER BY total_revenue DESC
;

-- Key insights:
-- • The top 35 products account for 80.84% of total company revenue.
--   These products are all mountain or road bikes.
--
-- • The top 50 products account for 90.26% of total company revenue.
--
-- • The remaining 245 products account for approximately 9.74% of total revenue,
--   demonstrating a strong concentration of revenue among a relatively small
--   group of products.
--
-- • 165 of the 295 products in the catalog have not generated any revenue.



/************************************************************************************************************************************************
11. LOWEST-REVENUE PRODUCTS
************************************************************************************************************************************************/

-- Business question:
-- Which products generate the lowest amount of revenue?

SELECT 
    product_name,
    category,
    subcategory,
    total_items_sold,
    total_revenue,
    revenue_rank,
    cum_percentage_rev,
    profit,
    profit_rank,
    Margin
FROM `portfolio-projects-494203.baraa_sales_analysis.product_analysis`
ORDER BY total_revenue ASC
LIMIT 10
;

-- Key insights:
-- • The lowest-revenue products are mainly clothing items, such as socks, gloves,
--   and vests, as well as accessories such as cleaners, tires, and tubes.
--
-- • Although several of these products have relatively high margins, approximately
--   50% to 75%, their individual contribution to total revenue is very limited,
--   with each representing less than 0.33% of total revenue.



/************************************************************************************************************************************************
12. TOP PRODUCTS WITHIN EACH CATEGORY
************************************************************************************************************************************************/

-- Business question:
-- Which products perform best within each category in terms of revenue?

SELECT 
    product_name,
    category,
    subcategory,
    total_items_sold,
    total_revenue,
    category_revenue_rank,
    percentage_rev,
    profit,
    Margin
FROM `portfolio-projects-494203.baraa_sales_analysis.product_analysis`
WHERE category_revenue_rank BETWEEN 1 AND 3
ORDER BY
    category,
    total_revenue DESC
;

-- Key insights:
-- • Within Accessories, the Sport-100 Helmet products in different colors are
--   among the highest-revenue products.
--
-- • Within Bikes, the Mountain-200 Black-46, Mountain-200 Black-42, and
--   Mountain-200 Silver-38 are among the highest-revenue products.
--
-- • Within Clothing, Women's Mountain Shorts and the Long-Sleeve Logo Jersey
--   are among the highest-revenue products.
--
-- • There is still a substantial gap between the revenue generated by bicycles
--   and the best-performing products in Accessories and Clothing.
--
-- • The best-performing individual Accessories and Clothing products each account
--   for less than 0.09% of total company revenue.



/************************************************************************************************************************************************
13. MARKET PENETRATION
************************************************************************************************************************************************/

-- Business question:
-- Which products have the highest customer market penetration?
--
-- For this analysis, customer penetration is defined as the percentage of the
-- company's total customer base that purchased a particular product.
--
-- This metric helps identify products with broad customer reach, regardless
-- of their contribution to total revenue.

SELECT 
    product_name,
    category,
    subcategory,
    market_penetration,
    total_items_sold,
    total_revenue,
    percentage_rev,
    profit,
    Margin
FROM `portfolio-projects-494203.baraa_sales_analysis.product_analysis`
ORDER BY market_penetration DESC
;

-- Key insights:
-- • Products with the highest market penetration are predominantly accessories.
--   The Water Bottle - 30 oz. was purchased by approximately 22% of customers.
--
-- • Despite bicycles accounting for approximately 97% of total revenue, the bicycle
--   with the highest market penetration is the Mountain-200 Black-42, purchased by
--   only 3.27% of the total customer base.
--
-- • This highlights an important difference between revenue contribution and customer
--   reach: bicycles generate most of the company's revenue, while accessories reach
--   a much broader portion of the customer base.
--
-- • This difference may indicate an opportunity to use high-penetration accessories
--   as a cross-selling or customer-engagement channel for bicycle products.



/************************************************************************************************************************************************
14. YEAR-OVER-YEAR PRODUCT GROWTH
************************************************************************************************************************************************/

-- Business question:
-- How has product performance changed over time?
--
-- Because 2010 contains only one month of sales and the latest available information
-- corresponds to January 2014, the most reliable full-year comparison is between
-- 2011, 2012, and 2013.

WITH yoy_growth AS (

SELECT 
    product_name,
    category,
    subcategory,
    total_items_sold,
    total_revenue,
    revenue_2011,
    revenue_2012,
    revenue_2013,
    ROUND(
        SAFE_DIVIDE(
            revenue_2012 - revenue_2011,
            revenue_2011
        ) * 100,
        2
    ) AS YoY_growth_2012,
    ROUND(
        SAFE_DIVIDE(
            revenue_2013 - revenue_2012,
            revenue_2012
        ) * 100,
        2
    ) AS YoY_growth_2013,
    revenue_rank
FROM `portfolio-projects-494203.baraa_sales_analysis.product_analysis`
ORDER BY total_revenue DESC
)

SELECT 
    product_name,
    category,
    subcategory,
    total_items_sold,
    total_revenue, 
    revenue_2011,
    revenue_2012,
    revenue_2013,
    YoY_growth_2012,
    CASE
        WHEN revenue_2011 = 0
             AND revenue_2012 = 0
            THEN 'No previous nor current sales'

        WHEN revenue_2011 = 0
            THEN 'No previous sales'

        WHEN YoY_growth_2012 >= 30
            THEN 'High growth'

        WHEN YoY_growth_2012 > 0
            THEN 'Growing'

        WHEN YoY_growth_2012 < -30
            THEN 'High Decline'

        WHEN YoY_growth_2012 < 0
            THEN 'Declining'
    END AS growth_status_2012,
    YoY_growth_2013,
    CASE
        WHEN revenue_2012 = 0
             AND revenue_2013 = 0
            THEN 'No previous nor current sales'

        WHEN revenue_2012 = 0
            THEN 'No previous sales'

        WHEN YoY_growth_2013 >= 30
            THEN 'High growth'

        WHEN YoY_growth_2013 > 0
            THEN 'Growing'

        WHEN YoY_growth_2013 < -30
            THEN 'High Decline'

        WHEN YoY_growth_2013 < 0
            THEN 'Declining'
    END AS growth_status_2013,
    revenue_rank
FROM yoy_growth
ORDER BY total_revenue DESC
LIMIT 10
;

-- Key insights:
-- • Six of the historical top 10 products show high and consistent growth across
--   the analyzed years. All six are mountain bikes.
--
-- • The other four products in the historical top 10 did not record sales during
--   the most recent two full years analyzed. All four are road bikes.
--
-- • This suggests that the composition of the company's highest-revenue products
--   changed between 2011 and 2013, with mountain bikes becoming increasingly
--   prominent among the top-performing products.



/************************************************************************************************************************************************
15. EVOLUTION OF PRODUCT REVENUE RANKINGS
************************************************************************************************************************************************/

-- Business question:
-- How did the relative ranking of the highest-revenue products change between
-- 2011, 2012, 2013, and the entire historical period?

SELECT
    product_name,
    category,
    subcategory,
    total_revenue,
    revenue_2010,
    revenue_2011,
    revenue_2012,
    revenue_2013,

    RANK() OVER(
        ORDER BY revenue_2011 DESC
    ) AS revenue_rank_2011,

    RANK() OVER(
        ORDER BY revenue_2012 DESC
    ) AS revenue_rank_2012,

    RANK() OVER(
        ORDER BY revenue_2013 DESC
    ) AS revenue_rank_2013,

    revenue_rank,
    percentage_rev

FROM `portfolio-projects-494203.baraa_sales_analysis.product_analysis`

ORDER BY revenue_rank_2013 ASC
;



-- Key insights:
-- • In the most recent full year, six of the products with the highest revenue
--   were also part of the historical top 10. These products belong mainly to the
--   Mountain-200 Black and Silver lines.
--
-- • The other four products in the historical top 10 include Touring-1000 Blue
--   and Road-350-W Yellow models.
--
-- • Most of these products were introduced in 2012, while one was introduced in 2013.
--
-- • Their subsequent contribution to revenue was substantial enough for several
--   of these newer products to enter the historical top 20 ranking.



/************************************************************************************************************************************************
KEY BUSINESS INSIGHTS
************************************************************************************************************************************************/

/*
1) PRODUCT PORTFOLIO AND REVENUE CONCENTRATION
-- 96.46% of historical revenue comes from bicycles, with 15,205 units sold and total revenue of USD 28,316,272.
-- Revenue is highly concentrated at the product level:
-- the top 10 products generate 42.49% of total company revenue, while
-- the top 35 products account for 80.84% of total revenue.


2) PRODUCTS WITH NO RECORDED SALES
-- The product catalog contains 295 products, of which 130 recorded sales during the analysis period and 165 did not record any sales.
-- Components account for the largest number of products without recorded sales with 127 products.
-- This provides an opportunity to investigate product demand, assortment decisions, product lifecycle, 
-- and inventory or distribution considerations.


3) LOWEST-REVENUE PRODUCTS
-- The lowest-revenue products are mainly clothing items such as socks, gloves,
-- and vests, as well as accessories such as cleaners, tires, and tubes.
-- Several of these products have relatively high margins, but their contribution to total revenue is very limited.


4) TOP-PERFORMING PRODUCTS
-- The top 10 products by historical revenue are all bicycles, consisting of
-- mountain and road bikes.
-- These products generate 42.49% of total company revenue and have margins
-- ranging approximately from 39% to 44%.


5) EVENUE CONTRIBUTION VS. CUSTOMER REACH
-- Bicycles generate approximately 97% of total revenue, but only 9,132 of the
-- 18,484 customers purchased a bicycle during the analysis period.
-- This contrasts with accessories, which represent only 3.76% of revenue but were purchased by approximately 82% of customers.
-- The data therefore shows a clear difference between revenue contribution and customer reach across product categories.


6) PRODUCT MARKET PENETRATION
-- Products with the highest market penetration are predominantly accessories.
-- The Water Bottle - 30 oz. was purchased by approximately 22% of customers.
-- Among bicycles, the Mountain-200 Black-42 has the highest market penetration, at approximately 3.27% of the total customer base.


7) PARETO CONCENTRATION
-- The top 35 products account for 80.84% of total revenue.
-- The top 50 products account for 90.26% of total revenue.
-- The remaining 245 products account for approximately 9.74% of total revenue.
-- This indicates that a relatively small number of products are responsible for most of the company's revenue.


8) CHANGES IN PRODUCT PERFORMANCE OVER TIME
-- Six of the historical top 10 products show high and consistent growth, and all six are mountain bikes.
-- The other four products in the historical top 10 did not record sales 
-- during the most recent two full years analyzed, and all four are road bikes.
-- New products introduced in 2012 and 2013 also entered the company's
-- highest-revenue rankings, indicating changes in the composition of the top-performing product portfolio.


9) BUSINESS RISK FROM REVENUE CONCENTRATION
-- The high concentration of revenue among a relatively small number of products
-- represents an important business consideration.
-- Changes in demand for these high-revenue products could have a disproportionate effect on total company revenue.
-- This should be considered together with their relatively limited customer reach, particularly for bicycle products.


10) POTENTIAL BUSINESS OPPORTUNITIES
-- The analysis suggests two complementary areas for further investigation:

-- 1. Strengthen the performance of high-revenue bicycle products by maintaining
--    availability and understanding the factors behind their sustained demand.

-- 2. Leverage the broad customer reach of accessories to develop cross-selling
--    opportunities and increase customer engagement with higher-value products.

-- Products with no recorded sales should also be evaluated to determine whether
-- they should remain in the assortment, require different commercial strategies, or should be discontinued.
-- Clothing represents a relatively weak contributor in terms of revenue and
-- sales volume and may require further analysis of demand and product assortment.
*/