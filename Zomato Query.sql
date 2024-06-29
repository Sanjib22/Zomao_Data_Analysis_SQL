USE zomato;

/* Question 1: What is the total amount each customer spent? */
SELECT
s.userid,
sum(p.price) AS total_spent
FROM
sales s
LEFT JOIN product p
ON p.product_id = p.product_id
GROUP BY
s.userid
ORDER BY
total_spent DESC;

/* Question 2: How many days has each customer ordered on Zomato? */

SELECT
userid,
COUNT(DISTINCT created_date) AS days_count
FROM
sales
GROUP BY
userid
ORDER BY
days_count DESC;

/* Question 3: Which was the first product purchased by each customer? */

WITH order_rank AS(
SELECT
userid,
created_date,
product_id,
DENSE_RANK() OVER(PARTITION BY userid ORDER BY created_date) AS rank_day
FROM
sales)
SELECT
userid,
product_id
FROM
order_rank
WHERE
rank_day=1;

/* Question 4: Which is the most purchased item on the menu and how many times was this item purchased by all customers? */

WITH popularity AS(
SELECT
product_id,
COUNT(*) AS total_order_count
FROM
sales
GROUP BY
product_id)
SELECT
userid,
s.product_id,
count(*) AS order_count,
total_order_count
FROM
sales s
JOIN popularity p ON s.product_id = p.product_id
WHERE
total_order_count = (SELECT MAX(total_order_count) FROM popularity)
GROUP BY
userid, s.product_id
ORDER BY
s.product_id;

/* Question 5: Which item was the most popular for each customer? */

WITH order_count AS(
SELECT
userid,
product_id,
count(*) AS order_counts
FROM
sales
GROUP BY
userid, product_id),

orders_rank AS
(SELECT
userid,
product_id,
order_counts,
DENSE_RANK() OVER(PARTITION BY userid ORDER BY order_counts DESC) AS order_rank
FROM
order_count)
SELECT
userid,
product_id,
order_counts
FROM
orders_rank
WHERE
order_rank =1
ORDER BY
order_counts DESC;

/* Question 6: Which item was purchased immediately after joining membership by users? */

WITH order_rank AS(
SELECT
sales.userid,
gold_signup_date,
created_date,
product_id,
ROW_NUMBER() OVER(PARTITION BY sales.userid ORDER BY created_date) AS order_rank
FROM
sales
INNER JOIN goldusers_signup gold
ON sales.userid = gold.userid
WHERE
created_date >= gold_signup_date)
SELECT
userid,
created_date,
gold_signup_date,
product_id
FROM
order_rank
WHERE
order_rank =1
ORDER BY
userid;

/* Question 7: Which item was purchased immediately before joining membership by users? */

WITH order_rank AS(
SELECT
sales.userid,
created_date,
gold_signup_date,
product_id,
DENSE_RANK() OVER(PARTITION BY sales.userid ORDER BY created_date DESC) AS order_rank
FROM
sales
INNER JOIN goldusers_signup gold
ON sales.userid = gold.userid
WHERE
created_date < gold_signup_date)
SELECT
userid,
gold_signup_date,
created_date,
product_id
FROM
order_rank
WHERE
order_rank =1
ORDER BY
userid;

/* Question 8: What are the total orders placed and the amount spent by each gold member before they became a member? */

WITH order_summary AS(
SELECT
sales.userid,
COUNT(created_date) AS total_order,
SUM(price) AS total_amount_spent
FROM
sales
INNER JOIN goldusers_signup gold
ON sales.userid = gold.userid
INNER JOIN  product ON sales.product_id = product.product_id
WHERE
created_date < gold_signup_date
GROUP BY
sales.userid)
SELECT
userid,
total_order,
total_amount_spent
FROM
order_summary
ORDER BY
total_amount_spent DESC;

/* Question 9: What are the total orders and the amount spent for each gold member after they became a member? */

WITH order_summary AS(
SELECT
sales.userid,
COUNT(created_date) AS total_order,
SUM(price) AS total_amount_spent
FROM
sales
INNER JOIN goldusers_signup gold
ON sales.userid = gold.userid
INNER JOIN  product ON sales.product_id = product.product_id
WHERE
created_date >= gold_signup_date
GROUP BY
sales.userid)
SELECT
userid,
total_order,
total_amount_spent
FROM
order_summary
ORDER BY
total_amount_spent DESC;

/* Question 10:
Zomato Points:
2 Zomato points = 5 Rs. Cashback
Zomato Points Calculation:
Each 5 rupees spent: 2 Zomato points
AND
Product 1: Each 5 rupees spent: 1 Zomato point
Product 2: Each 10 rupees spent: 5 Zomato points
Product 3: Each 5 rupees spent: 1 Zomato point

What is the amount of total Zomato points collected by each user?
*/

WITH total_spents1 AS(
SELECT
s.userid,
sum(p.price) AS total_spent1
FROM
sales s
INNER JOIN product p
ON s.product_id = p.product_id
GROUP BY
s.userid),

total_spents2 AS(
SELECT
s.userid,
s.product_id,
sum(p.price) AS total_spent2
FROM
sales s
INNER JOIN product p
ON s.product_id = p.product_id
GROUP BY
s.userid, s.product_id),

zomato_points AS(
SELECT
total_spents1.userid,
ROUND(total_spent1/5)*2 AS total_spent_points,
SUM(CASE
WHEN total_spents2.product_id = 1 THEN ROUND(total_spent2/5)*1
WHEN total_spents2.product_id = 2 THEN ROUND(total_spent2/10)*5
WHEN total_spents2.product_id = 3 THEN ROUND(total_spent2/5)*1
ELSE 0
END) AS product_spent_points
FROM
total_spents1
INNER JOIN total_spents2
ON total_spents1.userid = total_spents2.userid
GROUP BY
total_spents1.userid)
SELECT
userid,
(total_spent_points+product_spent_points) AS zomato_points,
(total_spent_points+product_spent_points)*2.5 AS cashback_earned
FROM
zomato_points
ORDER BY
zomato_points DESC;

/* Question 11:
Zomato Points:
2 Zomato points = 5 Rs. Cashback
Zomato Points Calculation:
Each 5 rupees spent: 2 Zomato points
AND
Product 1: Each 5 rupees spent: 1 Zomato point
Product 2: Each 10 rupees spent: 5 Zomato points
Product 3: Each 5 rupees spent: 1 Zomato point

For which product have the most Zomato points been given?
*/

WITH total_spents AS(
SELECT
s.userid,
s.product_id,
sum(p.price) AS total_spent
FROM
sales s
INNER JOIN product p
ON s.product_id = p.product_id
GROUP BY
s.userid, s.product_id),

zomato_points AS(
SELECT
product_id,
SUM(CASE
WHEN product_id = 1 THEN ROUND(total_spent/5)*1
WHEN product_id = 2 THEN ROUND(total_spent/10)*5
WHEN product_id = 3 THEN ROUND(total_spent/5)*1
ELSE 0
END) AS product_spent_points
FROM
total_spents
GROUP BY
product_id)
SELECT
product_id,
product_spent_points
FROM
zomato_points
WHERE
product_spent_points  = (SELECT MAX(product_spent_points) FROM zomato_points);

/* In the first year after a customer joins the gold program (including their joining date), 
irrespective of what the customer has purchased, they earn 5 Zomato points for every 10 Rs. 
spent. Which gold user earned the most in the first year after joining the gold program? */

WITH zomato_points AS(
SELECT
gold.userid,
ROUND(SUM(p.price)/10)*5 AS total_points
FROM
goldusers_signup gold
LEFT JOIN
sales 
ON	gold.userid = sales.userid
JOIN
product p
ON p.product_id = sales.product_id
WHERE
created_date >= gold_signup_date AND created_date <= DATE_ADD(gold_signup_date, INTERVAL 1 YEAR)
GROUP BY
gold.userid)

SELECT
userid,
total_points
FROM
zomato_points
WHERE
total_points = (SELECT MAX(total_points) FROM zomato_points);

/* Rank all the monthly transactions of each year by the customers. */

WITH years AS (
SELECT
EXTRACT(YEAR FROM created_date) AS years,
EXTRACT(MONTH FROM created_date) AS months,
created_date,
userid
FROM
sales)
SELECT
userid,
years,
months,
created_date,
DENSE_RANK() OVER (PARTITION BY years, months ORDER BY created_date) AS txn_rank
FROM
years
ORDER BY
years, months, txn_rank, userid;

/* Question 14: Rank all the monthly transactions of each year by the gold customers. Mark 'Non-Gold-Member' for non-gold customers. */

WITH years AS (
SELECT
EXTRACT(YEAR FROM created_date) AS years,
EXTRACT(MONTH FROM created_date) AS months,
created_date,
userid
FROM
sales)
SELECT
y.userid,
years,
months,
created_date,
CASE
WHEN y.userid = gold.userid AND created_date >= gold_signup_date  THEN DENSE_RANK() OVER (PARTITION BY years, months ORDER BY created_date)
ELSE "Non-Gold-Member"
END AS txn_rank
FROM
years y
LEFT JOIN
goldusers_signup gold
ON gold.userid = y.userid
ORDER BY
years, months, txn_rank, userid;
