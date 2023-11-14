# Case 2 - Pizza Runner

# Business Requirement

Danny wants to expand his new Pizza Empire - he was going to Uberize it - and so Pizza Runner was launched!
Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters.

# Entity Relationship Diagram 

# Questions & Answers

-- A. Pizza Metrics
-- 1. How many pizzas were ordered?
```sql
SELECT COUNT(pizza_id)
FROM pizza_runner.customer_orders;
 ```
-- 2. How many unique customer orders were made?
```sql
SELECT COUNT(DISTINCT customer_id)
FROM pizza_runner.customer_orders;
 ```
-- 3. How many successful orders were delivered by each runner?
```sql
SELECT COUNT(distance)
FROM pizza_runner.runner_orders
WHERE distance IS NOT NULL;
 ```
-- 4. How many of each type of pizza was delivered?
```sql
SELECT pizza_id, COUNT(pizza_id)
FROM pizza_runner.customer_orders
GROUP BY pizza_id
ORDER BY pizza_id;
 ```
-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
SELECT customer_orders.customer_id, pizza_names.pizza_name, COUNT(customer_orders.pizza_id) AS Total_Pizza
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.pizza_names 
ON customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY customer_orders.customer_id, pizza_names.pizza_name
ORDER BY customer_orders.customer_id ASC;
 ```
-- 6. What was the maximum number of pizzas delivered in a single order?
```sql
SELECT order_id, COUNT(order_id)
FROM pizza_runner.customer_orders
GROUP BY order_id
ORDER BY order_id ASC;
 ```
-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
SELECT customer_orders.customer_id, 
SUM(CASE WHEN customer_orders.exclusions OR customer_orders.extras IS NULL THEN 1 ELSE 0 END) AS Change_Count_NULL,
SUM(CASE WHEN customer_orders.exclusions OR customer_orders.extras IS NOT NULL THEN 1 ELSE 0 END) AS Change_Count_Non_NULL
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.runner_orders 
	ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.distance IS NOT NULL
GROUP BY customer_orders.customer_id
ORDER BY customer_orders.customer_id;
 ```
-- 8. How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT customer_orders.order_id,
SUM(CASE WHEN customer_orders.exclusions AND customer_orders.extras IS NOT NULL THEN 1 ELSE 0 END) AS Count_Pizza
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.runner_orders 
	ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.distance IS NOT NULL
AND customer_orders.exclusions IS NOT NULL
AND customer_orders.extras IS NOT NULL
GROUP BY customer_orders.order_id;
```
-- 9. What was the total volume of pizzas ordered for each hour of the day?
```sql
SELECT 
	HOUR(order_time) AS Hour_Day,
    COUNT(*) AS Total_Pizza
FROM pizza_runner.customer_orders
GROUP BY Hour_Day
ORDER BY Hour_Day;
```
-- 10. What was the volume of orders for each day of the week?
```sql
SELECT
	DAYOFWEEK(order_time) AS Day_Week,
    COUNT(*) AS Total_Order
FROM pizza_runner.customer_orders
GROUP BY Day_Week
ORDER BY Day_Week; 
```
-- B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
SELECT 
	CASE
		WHEN runners.registration_date BETWEEN '2021-01-01 00:00:00' AND '2021-01-07 23:59:59' THEN 1
        WHEN runners.registration_date BETWEEN '2021-01-08 00:00:00' AND '2021-01-14 23:59:59' THEN 2
        WHEN runners.registration_date BETWEEN '2021-01-14 00:00:00' AND '2021-01-21 23:59:59' THEN 3
        ELSE runners.registration_date
	END AS Registration_Week,
    COUNT(*) AS Runner_Count
FROM pizza_runner.runners
GROUP BY Registration_Week
ORDER BY Registration_Week;
```sql
/* Another alternative query */
SELECT 
	WEEK(registration_date) AS Registration_Week,
    COUNT(runner_id) AS Count_Runners
FROM pizza_runner.runners
GROUP BY Registration_Week
ORDER BY Registration_Week;
```
-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
SELECT runner_orders.runner_id,
	ROUND(AVG(TIMESTAMPDIFF(MINUTE, customer_orders.order_time, runner_orders.pickup_time)),0) AS DateDiff
FROM pizza_runner.runner_orders
INNER JOIN pizza_runner.customer_orders ON customer_orders.order_id = runner_orders.order_id
GROUP BY runner_orders.runner_id;
```
-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
/* Table calculating the prep time and number of pizzas for each order */
SELECT 
	customer_orders.order_id, 
    COUNT(customer_orders.pizza_id) AS Count_Pizza, 
    TIMESTAMPDIFF(MINUTE, customer_orders.order_time, runner_orders.pickup_time) AS PrepTimePizza
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.runner_orders ON customer_orders.order_id = runner_orders.order_id
GROUP BY customer_orders.order_id, PrepTimePizza;

/* Table calculating the average time it takes to prepare each count of pizzas */ 
WITH Pizza_Prep_CTE AS (
	SELECT 
		order_id,
        COUNT(pizza_id) AS Pizza_Count
	FROM pizza_runner.customer_orders
	GROUP BY order_id
)
SELECT 
	DISTINCT Pizza_Prep_CTE.Pizza_Count,
    AVG(TIMESTAMPDIFF(MINUTE, customer_orders.order_time, runner_orders.pickup_time)) AS PrepTimePizza
FROM Pizza_Prep_CTE
INNER JOIN customer_orders ON customer_orders.order_id = Pizza_Prep_CTE.order_id
INNER JOIN runner_orders ON runner_orders.order_id = customer_orders.order_id
GROUP BY Pizza_Prep_CTE.Pizza_Count;
```
-- 4. What was the average distance travelled for each customer?
```sql
SELECT 
	customer_orders.customer_id,
    ROUND(AVG(runner_orders.distance),0) AS AVG_Distance
FROM pizza_runner.customer_orders
INNER JOIN runner_orders ON runner_orders.order_id = customer_orders.order_id
GROUP BY customer_orders.customer_id;
```
-- 5. What was the difference between the longest and shortest delivery times for all orders?
```sql
SELECT 
MAX(runner_orders.duration) AS Longuest_Order, 
MIN(runner_orders.duration) AS Shortest_Order,
MAX(runner_orders.duration) - MIN(runner_orders.duration) AS Difference_Time
FROM pizza_runner.runner_orders;
```
-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
SELECT
    runner_orders.order_id,
    runner_orders.runner_id,
    COUNT(customer_orders.pizza_id) AS Pizza_Count,
    runner_orders.distance,
    runner_orders.duration AS Duration_Min,
    runner_orders.duration/60 AS Duration_Hour,
    ROUND(runner_orders.distance/(runner_orders.duration/60),0) AS Speed_Runner
FROM pizza_runner.runner_orders
INNER JOIN customer_orders ON runner_orders.order_id = customer_orders.order_id
GROUP BY 
	runner_orders.order_id,
    runner_orders.runner_id,
    runner_orders.distance,
    runner_orders.duration
ORDER BY Speed_Runner DESC;
```
-- 7. What is the successful delivery percentage for each runner?
```sql
-- ASSUMPT: success is based on if the order was delivered or not

SELECT 
	runner_orders.runner_id,
    ROUND(100 * SUM(CASE 
		WHEN runner_orders.cancellation IS NULL THEN 1
        ELSE 0
	END)/COUNT(*),0)  AS Rate_Success 
FROM pizza_runner.runner_orders
GROUP BY runner_orders.runner_id;
```
