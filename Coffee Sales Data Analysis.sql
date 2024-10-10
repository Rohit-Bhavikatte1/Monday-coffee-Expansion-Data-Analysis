
--- Coffee Data Analysis

SELECT * FROM city
SELECT * FROM  customers
SELECT * FROM products
SELECT * FROM sales


--- Q1.
--- Coffee Consumer count
--- How many people in each city are estimated to consumer coffee, given that 25% of population does ?

SELECT
	city_id,
	city_name,
	ROUND(
	(CAST(population AS FLOAT) *0.25)/1000000,2) AS Coffee_consumers_In_Millions,
city_rank
FROM city
ORDER BY population DESC


--- Q.2
--- Total Revenue from Coffee Sales
--- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
	cit.city_name,
	DATEPART (QUARTER ,sale_date) AS qtr,
	DATEPART (YEAR , sale_date) AS years,
	SUM(sal.total) AS TotalRevenue
FROM sales AS sal
JOIN customers AS cus
ON sal.customer_id =cus.customer_id
JOIN city AS cit
ON cus.city_id = cit.city_id
WHERE DATEPART (YEAR ,sale_date) = 2023
      AND
	  DATEPART (QUARTER ,sale_date) = 4
GROUP BY
	cit.city_name,
	DATEPART (QUARTER ,sale_date),
	DATEPART (YEAR , sale_date) 
ORDER BY TotalRevenue DESC



--- Q.3
--- Sales Count for Each Product
--- How many units of each coffee product have been sold?


SELECT
	sal.product_id,
	pro.product_name,
COUNT(sal.product_id)  AS TotalCount 
FROM sales AS sal
JOIN products AS pro
ON sal.product_id = pro.product_id
GROUP BY
	sal.product_id,
	pro.product_name
ORDER BY TotalCount DESC


--- Q.4
--- Average sales amount per city
--- What is the average sales amount per customer in each city ?

SELECT 
    cit.city_name,
	COUNT (DISTINCT cus.customer_id) AS TotalCustomers,
	SUM(sal.total) AS TotalRevenue,
	SUM(sal.total) / COUNT (DISTINCT cus.customer_id)  AS AvgSales
FROM sales AS sal
JOIN customers AS cus
ON sal.customer_id = cus.customer_id
JOIN city AS cit
ON cus.city_id = cit.city_id
GROUP BY
	cit.city_name
ORDER BY AvgSales DESC


--- Q.5
--- City Population and Coffee consumers
--- Provide a list of cities along with their population and estimated coffee consumer
--- return city_name , total current customers , estimated coffee consumers (25%)

WITH city_cte AS (
	SELECT 
		city_name,
		population,
		ROUND((CAST(population AS FLOAT) * 0.25) / 1000000,2) AS EstConsumers_mills
	FROM city),

	consumer_cte AS ( 
		SELECT 
		cit.city_name,
		COUNT(DISTINCT cus.customer_id) AS TotalConsmers
	FROM city AS cit
	JOIN customers AS cus
	ON cit.city_id = cus.city_id
	GROUP BY
	cit.city_name
	)

SELECT 
	city.city_name,
	city.population,
	city.EstConsumers_mills,
	con.TotalConsmers
FROM city_cte AS city
JOIN consumer_cte AS con
ON city.city_name = con.city_name
ORDER BY
EstConsumers_mills DESC
	


--- Q.6
--- Top Selling product by city
--- What are the top 3 selling products in each city based on sales volume


SELECT
* 
FROM
(
	SELECT 
		cit.city_name,
		pro.product_name,
		COUNT(sal.sale_id) AS TotalCount,
		DENSE_RANK() OVER(PARTITION BY cit.city_name ORDER BY COUNT(sal.sale_id) DESC) AS Ranks
	FROM city AS cit
	JOIN customers AS cus
	ON cit.city_id = cus.city_id
	JOIN sales AS sal
	ON cus.customer_id = sal.customer_id
	JOIN products as pro
	ON sal.product_id = pro.product_id
	GROUP BY 
		cit.city_name,
		pro.product_name
	) AS t1
WHERE Ranks IN (1,2,3)



--- Q.7 
--- Customer Segmentation by City
--- How Many unique Customers are there in Each city who have purchased coffee products ?

SELECT 
	cit.city_name,
	COUNT(DISTINCT cus.customer_id) AS uniqueCustomers
	FROM customers AS cus
JOIN city AS cit
ON cus.city_id = cit.city_id
JOIN sales AS sal
ON cus.customer_id = sal.customer_id
GROUP BY cit.city_name
ORDER BY 
	cit.city_name ,
	uniqueCustomers DESC

---Q.8
--- Average sales VS Rent
--- Find each city and their average sales per customer and average rent per customer


--- Average sales per customer
WITH AvgSales_cte AS
(
SELECT 
    cit.city_name,
	COUNT (DISTINCT cus.customer_id) AS TotalCustomers,
	SUM(sal.total) AS TotalRevenue,
	SUM(sal.total) / COUNT (DISTINCT cus.customer_id)  AS AvgSalesPerCus
FROM sales AS sal
JOIN customers AS cus
ON sal.customer_id = cus.customer_id
JOIN city AS cit
ON cus.city_id = cit.city_id
GROUP BY
	cit.city_name
)
--- Average Rent per customer
SELECT 
	c.city_name,
	cte.AvgSalesPerCus,
	c.estimated_rent / TotalCustomers As AvgRentPerCustomer
FROM city AS c
JOIN AvgSales_cte AS cte
ON c.city_name = cte.city_name
ORDER BY 
cte.AvgSalesPerCus DESC


--- Q.9
--- Monthly Sales Growth
--- Sales Growth rate : Calculate percentage growth (incline .or decline ) in sales over different time periods (Monthly)
--- BY each city

WITH MonthlySale AS
(
    SELECT 
        cit.city_name AS City,
        DATEPART(MONTH, sal.sale_date) AS Months,
        DATEPART(YEAR, sal.sale_date) AS Years,
        SUM(sal.total) AS Totalsales
    FROM sales AS sal
    JOIN customers AS cus ON sal.customer_id = cus.customer_id
    JOIN city AS cit ON cus.city_id = cit.city_id
    GROUP BY 
        cit.city_name,
        DATEPART(MONTH, sal.sale_date), 
        DATEPART(YEAR, sal.sale_date) 
),
Sales_cte AS
(
    SELECT 
        City,
        Months,
        Years,
        Totalsales AS CurrentMonthSales,
        LAG(Totalsales, 1) OVER (PARTITION BY City ORDER BY Years, Months) AS LastMonthSales
    FROM MonthlySale
)
SELECT 
    City,
    Months,
    Years,
    CurrentMonthSales,
    LastMonthSales,
    CASE 
        WHEN LastMonthSales IS NOT NULL AND LastMonthSales != 0 THEN 
            ROUND ((CurrentMonthSales - LastMonthSales) / CAST(LastMonthSales AS FLOAT) * 100 ,2)
        ELSE 
            NULL -- Handle cases where there's no sales last month
    END AS SalesGrowth
FROM Sales_cte
WHERE 
       CurrentMonthSales IS NOT NULL
   AND 
       LastMonthSales IS NOT NULL




--- Q.10
--- Market Potential Analysis
--- Identify top 3 city based on highest sales , return city name , total rent, total customers, estimate coffe consumer,

WITH AvgSales_cte AS
(
SELECT 
    cit.city_name,
	COUNT (DISTINCT cus.customer_id) AS TotalCustomers,
	SUM(sal.total) AS TotalRevenue,
	SUM(sal.total) / COUNT (DISTINCT cus.customer_id)  AS AvgSalesPerCus
FROM sales AS sal
JOIN customers AS cus
ON sal.customer_id = cus.customer_id
JOIN city AS cit
ON cus.city_id = cit.city_id
GROUP BY
	cit.city_name
)
--- Average Rent per customer
SELECT 
	c.city_name,
	cte.AvgSalesPerCus,
	c.estimated_rent / TotalCustomers As AvgRentPerCustomer
FROM city AS c
JOIN AvgSales_cte AS cte
ON c.city_name = cte.city_name
ORDER BY 
cte.AvgSalesPerCus DESC



--- Q.10
--- Market Potential Analysis
--- Identify top 3 city based on highest sales , return city name , total rent, total customers, estimate coffe consumer,

WITH SalesCte AS
(
SELECT 
	cit.city_name,
	SUM(sal.total) AS TotalSales,
	COUNT(DISTINCT cus.customer_id) AS TotalCustomers,
	ROUND((CAST(cit.population AS FLOAT )* 0.25)/1000000,2) AS EstmatedCoffeConsumers_in_millions,
	SUM(sal.total) / COUNT (DISTINCT cus.customer_id)  AS AvgSalesPerCus
FROM city AS cit
JOIN customers AS cus
ON cit.city_id = cus.city_id
JOIN sales AS sal
ON cus.customer_id = sal.customer_id
GROUP BY 
cit.city_name,
cit.population
)
	SELECT 
	ci.city_name,
	cte.TotalSales,
	cte.TotalCustomers,
	ci.estimated_rent AS TotalRent,
	cte.EstmatedCoffeConsumers_in_millions,
	cte.AvgSalesPerCus,
	ci.estimated_rent / TotalCustomers As AvgRentPerCustomer

FROM city AS ci
JOIN SalesCte AS cte
ON ci.city_name = cte.city_name
ORDER BY 
TotalSales DESC

-- Conclusion :
-- Bases On my analysis the cities i can reccoment are :
-- 1. Pune 
-- Reason :
--   1. In Pune The average rent per customer is less that is 294.
--   2. The total Sales in Pune is very good that is 1258290 and estimated coffe consumer is 1.88 Millions.
--   3. In Pune there are 52 different customers .The average sales per customer is also good that is 24197.

-- 2. Jaipur
-- Reason :
--   1. In Jaipur The average rent per customer is very less that is 156.
--   2. The total Sales in Jaipur is good that is 803450 and estimated coffe consumer is 1 Million.
--   3. In Pune there are 69 different customers .The average sales per customer is also good that is 11644

-- 3. Delhi
--   1. The main reson to select Delhi is beacause the estimated coffe consumers are very high that is 7.75 Millions.
--   2. Total Sales are 750420 thats fine and average sales per customer is 750420.
--   3. There are 68 different customers in Delhi and the average rent per customer is 330 which is also good sign.
 
 
-- Conclusion :
--    The cities Pune, Jaipur and Delhi are Reccomented to open new stores. As we can see from above data
-- 	the Rent is very low and its under in 500 .
--	The Total Sales and Estimated coffe consumers are in very high in numbers especially in Delhi.






















