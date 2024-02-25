-- Retrieve the top 5 highest-paid employees for each department, sorted by salary in descending order.
SELECT
	department, id, name
FROM
	(SELECT
		department, id, name,
		RANK() OVER(PARTITION BY department ORDER BY salary DESC) salary_ranked
	FROM
		advanced_sql_queries.dbo.employees) ranked
WHERE salary_ranked <= 5;

-- Calculate the total sales for each month of the current year (Let's say today is 31/12/2023), including months with zero sales.
DECLARE @current_day date
SET @current_day = datefromparts(2023,12,31)
SELECT
	FORMAT(t1.month_series, 'yyyy-MM') AS year_month,
	COALESCE(SUM(revenue), 0) AS sales
FROM
	(SELECT
		DATEADD(month, value, datetrunc(year, @current_day)) month_series
	FROM
		generate_series(0,11,1)) t1
LEFT JOIN
	advanced_sql_queries.dbo.sales t2
ON datetrunc(month, t2.date) = t1.month_series
GROUP BY t1.month_series;

-- Find customers who have made a purchase every month for the last six months.
DECLARE @current_day date
SET @current_day = datefromparts(2023,12,31)
SELECT
	customer_id
FROM -- Subquery to retrieve total revenue of each customer last 6 months
	(SELECT
		DATETRUNC(month,date) AS year_month,
		customer_id,
		SUM(revenue) AS sales
	FROM
		advanced_sql_queries.dbo.sales
	WHERE
		DATEADD(month, -5, DATETRUNC(month,@current_day)) <= DATETRUNC(month,date)
	GROUP BY
		DATETRUNC(month,date), customer_id) t
GROUP BY
	customer_id
HAVING
	COUNT(customer_id) = 6;

-- Calculate the running total of sales for each day within the past month.
DECLARE @current_day date
SET @current_day = datefromparts(2023,12,31)
SELECT
	day_series,
	SUM(Sales) OVER(ORDER BY day_series)
FROM
	(SELECT
		t1.day_series,
		SUM(revenue) as Sales
	FROM
		(
		SELECT DATEADD(day, value, datetrunc(MONTH, DATEADD(month,-1,@current_day))) AS day_series
		FROM generate_series(0, DAY(EOMONTH(DATEADD(month,-1,@current_day)))-1,1)) t1
	LEFT JOIN advanced_sql_queries.dbo.sales t2
	ON t2.date = t1.day_series
	GROUP BY t1.day_series) t3;

-- List the products that have been sold in all cities where the company operates.
SELECT DISTINCT
	s.product_id,
	p.name
FROM advanced_sql_queries.dbo.sales s
LEFT JOIN advanced_sql_queries.dbo.products p
ON s.product_id = p.id
WHERE
	s.location IN
	(SELECT
		id
	FROM
		advanced_sql_queries.dbo.locations
	WHERE
		company_operates = 'yes');

-- Retrieve the top 10 customers who have spent the most on their single purchase.
SELECT
	customer_id,
	name,
	revenue
FROM
	(SELECT
		s.customer_id,
		c.name,
		s.revenue,
		RANK() OVER(ORDER BY s.revenue DESC) ranked
	FROM
		advanced_sql_queries.dbo.sales s
	LEFT JOIN advanced_sql_queries.dbo.customers c
	ON
		s.customer_id = c.id) t
WHERE ranked <= 10;

-- Calculate the 30-day moving average of sales for each product.
SELECT
	product_id,
	date,
	AVG(SUM(revenue)) OVER(PARTITION BY product_id ORDER BY date ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) avg_sales
FROM
	advanced_sql_queries.dbo.sales
GROUP BY
	product_id, date;

-- List the departments where the average salary is higher than the company's overall average salary.
SELECT
	department,
	AVG(salary) avg_salary
FROM
	advanced_sql_queries.dbo.employees
GROUP BY
	department
HAVING AVG(salary) >
	(SELECT
		AVG(salary)
	FROM
		advanced_sql_queries.dbo.employees);

-- Retrieve the top 3 most recent orders for each customer.
SELECT
	customer_id,
	revenue
FROM
	(SELECT 
		customer_id,
		revenue,
		RANK() OVER(PARTITION BY customer_id ORDER BY revenue DESC) ranked
	FROM
		advanced_sql_queries.dbo.sales) t
WHERE ranked <= 3;