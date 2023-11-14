# Case 1 - Danny's Diner

# Business Requirement

Understand clients' ordering and spending habits at the restaurant to expand the existing customer loyalty program. 

# Entity Relationship Diagram 

# Questions & Answers

-- 1. What is the total amount each customer spent at the restaurant?

SELECT sales.customer_id, sum(menu.price) AS Total_Order
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu ON sales. product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) AS nb_day
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

/* 
first item: based on 1st and earliest
each customer: group by customer_id
join sales and menu to get the full name of the product 
*/
/* SELECT sales.customer_id, sales.order_date, menu.product_name
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu ON sales.product_id = menu.product_id
GROUP BY customer_id, order_date, menu.product_name
ORDER BY order_date ASC
LIMIT 4; */

WITH RankSale AS (
  SELECT 
  	sales.customer_id,
  	sales.order_date,
  	menu.product_name,
  	DENSE_RANK () OVER (PARTITION BY sales.customer_id 
                        ORDER BY sales.order_date) AS RowNumber
  FROM dannys_diner.sales 
  INNER JOIN dannys_diner.menu ON sales.product_id = menu.product_id
  )
 SELECT customer_id, product_name
 FROM RankSale
 WHERE RowNumber = 1
 GROUP BY customer_id, product_name;
 
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT menu.product_name, COUNT(sales.product_id) AS Total_Purchase
FROM dannys_diner.menu
JOIN dannys_diner.sales ON menu.product_id = sales.product_id
GROUP BY menu.product_name
ORDER BY Total_Purchase DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH MaxProduct AS (
  SELECT 
  	sales.customer_id,
  	menu.product_name,
  	COUNT(menu.product_id) AS Count_Product,
  	DENSE_RANK() OVER (PARTITION BY sales.customer_id
                     ORDER BY COUNT(sales.customer_id) DESC) AS Ranking
  FROM dannys_diner.sales
  INNER JOIN dannys_diner.menu ON sales.product_id = menu.product_id
  GROUP BY sales.customer_id, menu.product_name
)
SELECT
  customer_id,
  product_name,
  Count_Product
FROM MaxProduct
WHERE Ranking = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH CTE_Purchase AS (
  SELECT 
  	members.customer_id,
  	sales.order_date,
  	sales.product_id,
  	DENSE_RANK () OVER(PARTITION BY members.customer_id 
                      ORDER BY sales.order_date) AS Ranking
  FROM dannys_diner.sales
  INNER JOIN dannys_diner.members 
  	ON sales.customer_id = members.customer_id
  	AND sales.order_date >= members.join_date
)
SELECT customer_id, order_date, product_name
FROM CTE_Purchase
INNER JOIN dannys_diner.menu ON CTE_Purchase.product_id = menu.product_id
WHERE Ranking = 1
ORDER BY customer_id ASC;

-- 7. Which item was purchased just before the customer became a member?

WITH CTE_Purchase AS (
  SELECT 
  	members.customer_id,
  	sales.order_date,
  	sales.product_id,
  	ROW_NUMBER () OVER(PARTITION BY members.customer_id 
                      ORDER BY sales.order_date DESC) AS Ranking
  FROM dannys_diner.sales
  INNER JOIN dannys_diner.members 
  	ON sales.customer_id = members.customer_id
  	AND sales.order_date < members.join_date
)
SELECT customer_id, order_date, product_name
FROM CTE_Purchase
INNER JOIN dannys_diner.menu ON CTE_Purchase.product_id = menu.product_id
WHERE Ranking = 1
ORDER BY customer_id ASC;

-- 8. What is the total items and amount spent for each member before they became a member?

WITH Total_Purchase AS (
  SELECT
    members.customer_id,
    sales.order_date,
    sales.product_id,
  	menu.product_name,
  	menu.price,
    ROW_NUMBER() OVER (PARTITION BY members.customer_id
                       ORDER BY sales.order_date DESC) AS Ranking
  FROM dannys_diner.members
  INNER JOIN dannys_diner.sales 
  	ON sales.customer_id = members.customer_id
  	AND sales.order_date < members.join_date
  INNER JOIN dannys_diner.menu
  	ON sales.product_id = menu.product_id
  )
SELECT customer_id, COUNT(product_id) AS Total_Product, SUM(price) AS Total_Price
FROM Total_Purchase
GROUP BY customer_id
ORDER BY customer_id; 

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH CTE_Points AS (
	SELECT
  		menu.product_id,
        CASE 
  			WHEN product_id = 1 THEN price * 20
            ELSE price * 10 
  		END AS Points
    FROM dannys_diner.menu
  )
SELECT sales.customer_id, SUM(CTE_Points.Points) AS Total_Points
FROM dannys_diner.sales
INNER JOIN CTE_Points 
	ON CTE_Points.product_id = sales.product_id
WHERE customer_id != 'C'
GROUP BY customer_id
ORDER BY customer_id; 

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

/*
ID all purchases made in January: contains 2021-01 only 
calculate the total poits
only select customer A and B
*/

SELECT sales.customer_id, COUNT(sales.product_id) * menu.price * 20 AS Total_Points
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu 
	ON sales.product_id = menu.product_id
WHERE sales.customer_id != 'C'
AND sales.order_date::text LIKE '2021-01%'
GROUP BY sales.customer_id, menu.price
ORDER BY sales.customer_id;
