CREATE DATABASE amazon_sales_project;
USE amazon_sales_project;

CREATE TABLE orders (OrderDate VARCHAR(20), OrderID INT, DeliveryDate VARCHAR(20), CustomerID BIGINT, 
                    Location VARCHAR(50), Zone VARCHAR(20), DeliveryType VARCHAR(50), 
                    ProductCategory VARCHAR(100), SubCategory VARCHAR(100), Product VARCHAR(255), 
                    UnitPrice INT, ShippingFee INT, OrderQuantity INT, SalePrice INT, 
                    Status VARCHAR(50), Reason VARCHAR(50), Rating INT, DeliveryDays INT, 
                    Year INT, OrderYear INT );
                    
CREATE TABLE customers ( CustomerID BIGINT, Customer_Age INT, Customer_Gender VARCHAR(10) );

SELECT CustomerID, COUNT(DISTINCT OrderID) AS order_count
FROM orders
GROUP BY CustomerID
HAVING order_count >= 5;   

WITH customer_metrics AS ( 
                          SELECT CustomerID, SUM(SalePrice * OrderQuantity) AS total_revenue,
                          COUNT(DISTINCT OrderID) AS order_frequency,
						  AVG(SalePrice * OrderQuantity) AS avg_order_value
                          FROM orders
                          GROUP BY CustomerID
),
normalized AS (
               SELECT *,
			   total_revenue / MAX(total_revenue) OVER() AS norm_revenue, 
               order_frequency / MAX(order_frequency) OVER() AS norm_frequency, 
			   avg_order_value / MAX(avg_order_value) OVER() AS norm_aov
               FROM customer_metrics
),
scored AS (
           SELECT *,
           (0.5 * norm_revenue + 0.3 * norm_frequency + 0.2 * norm_aov) AS composite_score
           FROM normalized 
)
SELECT CustomerID, total_revenue, order_frequency, avg_order_value, composite_score
FROM scored
ORDER BY composite_score DESC
LIMIT 5;


WITH customer_revenue AS (
                          SELECT CustomerID, SUM(SalePrice * OrderQuantity) AS total_revenue
                          FROM orders
                          GROUP BY CustomerID
),
avg_revenue AS (
			   SELECT AVG(total_revenue) AS avg_rev
               FROM customer_revenue
)
SELECT cr.CustomerID, cr.total_revenue
FROM customer_revenue cr, avg_revenue ar
WHERE cr.total_revenue > 1.3 * ar.avg_rev
ORDER BY cr.total_revenue DESC; 

WITH base AS (
              SELECT STR_TO_DATE(OrderDate, '%d-%b-%y') AS order_date, ProductCategory,
              SalePrice * OrderQuantity AS revenue
              FROM orders
),
yearly_revenue AS (
                  SELECT YEAR(order_date) AS year, ProductCategory, SUM(revenue) AS revenue
                  FROM base
				  GROUP BY YEAR(order_date), ProductCategory
),
yoy_growth AS (
			  SELECT year, ProductCategory, revenue, 
              LAG(revenue) OVER (PARTITION BY ProductCategory ORDER BY year) AS prev_year_revenue
              FROM yearly_revenue
)
SELECT ProductCategory, year, revenue, prev_year_revenue,
ROUND(((revenue - prev_year_revenue) / prev_year_revenue) * 100, 2)AS yoy_growth_percentage
FROM yoy_growth
WHERE prev_year_revenue IS NOT NULL
ORDER BY yoy_growth_percentage DESC
LIMIT 3;    



          