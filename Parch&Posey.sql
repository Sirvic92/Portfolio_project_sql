/*
Parch and Posey Data Exploration. 
Specifically using the following queries: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions,
Creating Views, Converting Data Types
*/

/*
There are about 5 tables Used in this exploratory analysis on sql which are orders, accounts, region, 
sales_rep and web_events.
*/

/* 
Viewing the different tables 
*/
Select *
From Orders
WHERE occurred_at is not null 
ORDER BY 3
/* The order table has the following columns: 
-- id = the row index
-- account_id  = customers account number 
-- occurred_at = The transaction date 
-- standard_qty = The quantity of the standard paper type bought 
-- poster_qty = The quantity of the poster paper type bought 
-- gloss_qty = The quantity of the gloss paper type bought 
-- total = the sum of standard_qty + poster_qty+ gloss_qty
-- standard_amt_usd = The amount realized on standard_qty per sale
-- poster_amt_usd = The amount realized on poster_qty per sale
-- gloss_amt_usd = The amount realized on gloss_qty per sale
-- total_amt_usd = The sum of standard_amt_usd + poster_amt_usd+ gloss_amt_usd 
*/
Select *
From Orders

ORDER BY id

/* The account table has the following columns: 
-- id = the account_id
--  name  = account name or customer name
-- website= The website of the account name or customer
-- lat = latitude  
-- long = longitude
-- primary_poc = Primary point of contact.
-- sales_rep_id = The id of the sales representative
*/
Select *
From region

/* The region table has the following columns: 
-- id = the region id
--  name  = The name of the rregion
*/
Select *
From sales_reps
/* The slaes_reps table has the following columns: 
-- id = the sales representative id
--  name  = The sales representative name
-- region_id = The region of the sales_representative 
*/
Select *
From web_events
/* The web_events table has the following columns: 
-- id = the row index 
--  account_id  = account_number of the customer
-- occurred_at = The event_date
--- channel = The medium of the event
*/
/* EXPLORATION PROPER */

-- Exploring the total amount of poster_qty paper ordered in the orders table.
SELECT SUM(poster_qty) AS total_poster_sales
FROM orders;
-- Exploring total amount of standard_qty paper ordered in the orders table.
SELECT SUM(standard_qty) AS total_poster_sales
FROM orders;
-- Finding the total dollar amount of sales using the total_amt_usd in the orders table.
SELECT SUM(total_amt_usd) AS total_dollar_sales
FROM orders;
-- Finding the standard_amt_usd per unit of standard_qty paper.
SELECT SUM(standard_amt_usd)/SUM(standard_qty) AS standard_price_per_unit
FROM orders;

-- the earliest order ever placed?
SELECT MIN(occurred_at) 
FROM orders;
-- Finding the mean (AVERAGE) amount spent per order on each paper type, as well as the mean amount of each paper type purchased per order.
SELECT AVG(standard_qty) mean_standard, AVG(gloss_qty) mean_gloss, 
           AVG(poster_qty) mean_poster, AVG(standard_amt_usd) mean_standard_usd, 
           AVG(gloss_amt_usd) mean_gloss_usd, AVG(poster_amt_usd) mean_poster_usd
FROM orders;

/* exploring the name for each region for every order, as well as the account name and the unit price 
they paid for the order. However, the results is provided if the standard order 
quantity exceeds 100 and the poster order quantity exceeds 50 */
-- o.total + 0.0000001 because some entries has total as zero and so the division by zero is indeterminate 
SELECT r.name region, a.name account, CAST(o.total_amt_usd)/CAST(o.total + 0.0000001) unit_price
FROM region r
JOIN sales_reps s
ON s.region_id = r.id
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
WHERE o.standard_qty > 100 AND o.poster_qty > 50
ORDER BY unit_price;

/* Exploring the region for each sales_rep along with their associated accounts. 
This time only for the Midwest region */

SELECT r.name region, s.name rep, a.name account
FROM sales_reps s
JOIN region r
ON s.region_id = r.id
JOIN accounts a
ON a.sales_rep_id = s.id
WHERE r.name = 'Midwest'
ORDER BY a.name;

/* Exploring  all the orders that occurred in 2015.*/
SELECT o.occurred_at, a.name, o.total, o.total_amt_usd
FROM accounts a
JOIN orders o
ON o.account_id = a.id
WHERE o.occurred_at BETWEEN '01-01-2015' AND '01-01-2016'
ORDER BY o.occurred_at DESC;

-- Determining the number of times a particular channel was used in the web_events table for each sales rep
SELECT s.name, w.channel, COUNT(*) num_events
FROM accounts a
JOIN web_events w
ON a.id = w.account_id
JOIN sales_reps s
ON s.id = a.sales_rep_id
GROUP BY s.name, w.channel
ORDER BY num_events DESC;
-- Determining the number of times a particular channel was used in the web_events table for each region
SELECT r.name, w.channel, COUNT(*) num_events
FROM accounts a
JOIN web_events w
ON a.id = w.account_id
JOIN sales_reps s
ON s.id = a.sales_rep_id
JOIN region r
ON r.id = s.region_id
GROUP BY r.name, w.channel
ORDER BY num_events DESC;

-- How many of the sales reps have more than 5 accounts that they manage?
SELECT s.id, s.name, COUNT(*) num_accounts
FROM accounts a
JOIN sales_reps s
ON s.id = a.sales_rep_id
GROUP BY s.id, s.name
HAVING COUNT(*) > 5
ORDER BY num_accounts;


-- Checking if any sales reps worked on more than one account?
/* The below two queries have the same number of resulting rows (351), so we know that every account is associated with 
only one region. If each account was associated with more than one region, the first query should have 
returned more rows than the second query.*/

SELECT s.id, s.name, COUNT(*) num_accounts
FROM accounts a
JOIN sales_reps s
ON s.id = a.sales_rep_id
GROUP BY s.id, s.name
ORDER BY num_accounts;

-- AND

SELECT DISTINCT id, name
FROM sales_reps;

/* We would like to understand 3 different levels of customers based on the amount associated with their purchases. 
The top level includes anyone with a Lifetime Value (total sales of all orders) greater than 200,000 usd. 
The second level is between 200,000 and 100,000 usd. The lowest level is anyone under 100,000 usd.*/

SELECT a.name, SUM(total_amt_usd) total_spent, 
     CASE WHEN SUM(total_amt_usd) > 200000 THEN 'top'
     WHEN  SUM(total_amt_usd) > 100000 THEN 'middle'
     ELSE 'low' END AS customer_level
FROM orders o
JOIN accounts a
ON o.account_id = a.id 
GROUP BY a.name
ORDER BY 2 DESC;

/* We would now like to perform a similar calculation to the one above, but we want to 
obtain the total amount spent by customers only in 2016 and 2017..*/
SELECT a.name, SUM(total_amt_usd) total_spent, 
     CASE WHEN SUM(total_amt_usd) > 200000 THEN 'top'
     WHEN  SUM(total_amt_usd) > 100000 THEN 'middle'
     ELSE 'low' END AS customer_level
FROM orders o
JOIN accounts a
ON o.account_id = a.id
WHERE occurred_at > '2015-12-31' 
GROUP BY 1
ORDER BY 2 DESC;

-- The name of the sales_rep in each region with the largest amount of total_amt_usd sales.
WITH t1 AS (
  SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
   FROM sales_reps s
   JOIN accounts a
   ON a.sales_rep_id = s.id
   JOIN orders o
   ON o.account_id = a.id
   JOIN region r
   ON r.id = s.region_id
   GROUP BY 1,2
   ORDER BY 3 DESC), 
t2 AS (
   SELECT region_name, MAX(total_amt) total_amt
   FROM t1
   GROUP BY 1)
SELECT t1.rep_name, t1.region_name, t1.total_amt
FROM t1
JOIN t2
ON t1.region_name = t2.region_name AND t1.total_amt = t2.total_amt;

-- Exploring the total orders placed for the region with the largest sales total_amt_usd
WITH t1 AS (
   SELECT r.name region_name, SUM(o.total_amt_usd) total_amt
   FROM sales_reps s
   JOIN accounts a
   ON a.sales_rep_id = s.id
   JOIN orders o
   ON o.account_id = a.id
   JOIN region r
   ON r.id = s.region_id
   GROUP BY r.name), 
t2 AS (
   SELECT MAX(total_amt)
   FROM t1)
SELECT r.name, COUNT(o.total) total_orders
FROM sales_reps s
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
JOIN region r
ON r.id = s.region_id
GROUP BY r.name
HAVING SUM(o.total_amt_usd) = (SELECT * FROM t2);

-- Exploring how many accounts still had more in total purchases for the account that purchased the most (in total over their lifetime as a customer) standard_qty paper, 
WITH t1 AS (
  SELECT a.name account_name, SUM(o.standard_qty) total_std, SUM(o.total) total
  FROM accounts a
  JOIN orders o
  ON o.account_id = a.id
  GROUP BY 1
  ORDER BY 2 DESC
  LIMIT 1), 
t2 AS (
  SELECT a.name
  FROM orders o
  JOIN accounts a
  ON a.id = o.account_id
  GROUP BY 1
  HAVING SUM(o.total) > (SELECT total FROM t1))
SELECT COUNT(*)
FROM t2;

-- Creating a Running total over the years
SELECT standard_amt_usd,
       DATE_TRUNC('year', occurred_at) as year,
       SUM(standard_amt_usd) OVER (PARTITION BY DATE_TRUNC('year', occurred_at) ORDER BY occurred_at) AS running_total
FROM orders

-- Determining how the current order's total revenue ("total" meaning from sales of all types of paper) compares to the next order's total revenue.
SELECT account_id,
       standard_sum,
       LAG(standard_sum) OVER (ORDER BY standard_sum) AS lag,
       LEAD(standard_sum) OVER (ORDER BY standard_sum) AS lead,
       standard_sum - LAG(standard_sum) OVER (ORDER BY standard_sum) AS lag_difference,
       LEAD(standard_sum) OVER (ORDER BY standard_sum) - standard_sum AS lead_difference
FROM (
SELECT account_id,
       SUM(standard_qty) AS standard_sum
  FROM orders 
 GROUP BY 1
 ) sub
 
 -- Using the NTILE functionality to divide the accounts into 4 levels in terms of the amount of standard_qty for their orders
 SELECT
       account_id,
       occurred_at,
       standard_qty,
       NTILE(4) OVER (PARTITION BY account_id ORDER BY standard_qty) AS standard_quartile
  FROM orders 
 ORDER BY account_id DESC










