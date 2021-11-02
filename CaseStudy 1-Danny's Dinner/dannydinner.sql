/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

--1. What is the total amount each customer spent at the restaurant?**

  /*Price is in menu table so joining sales with menu.Since we need amount for  `each customer` we group by customer_id 
  and we need total so using aggregate function `SUM`.*/

SELECT 
	sales.customer_id,
  SUM(menu.price) AS total_spent
FROM dannys_diner.sales
JOIN dannys_diner.menu
	ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;

--Output:

| customer_id  | total_spent  |
|--------------|--------------|
| A            | 76           |
| B            | 74           |
| C            | 36           |


/*Insights:

Customer `A` spent 76$ in total, Customer `B` spent 74$ in total and Customer `C` spent only 36$ in total.*/

/*2. How many days has each customer visited the restaurant?**
 We need  `each customer`, so we group by customer and we need count  so using aggregate function `COUNT`*/

SELECT
  customer_id,
  COUNT (DISTINCT order_date) AS visited_days
FROM dannys_diner.sales
GROUP BY customer_id;

--Output:

| customer_id  | visited_days  |
|--------------|-------------- |
| A            | 4             |
| B            | 6             |
| C            | 2             |


/*Insights:

Customer `B` visited the store 6 times, customer `A` 4 times and customer `C` only 2 times.*/

--3. What was the first item from the menu purchased by each customer?

/*In this question , how do we know which item they purchased, for first time there is not time field.
For eg customer A ordered Sushi and Curry , so should we assume since Sushi was first inserted therefore that was first item. 
Product name is in menu table so joining sales with menu.
Using Window function `ROW_NUMBER`  that assigns a sequential integer to each row in a result set and partitioning by customer id. 
and then filtering the result set where first purchase is 1 */

WITH cte_order AS (
  SELECT
    sales.customer_id,
    menu.product_name,
    ROW_NUMBER() OVER(
     PARTITION BY sales.customer_id
      ORDER BY 
        sales.order_date,  
        sales.product_id
    ) AS first_purchase
    FROM dannys_diner.sales
    JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
)
SELECT * FROM cte_order
WHERE first_purchase = 1;

--Output:

| customer_id  | product_name  | first_purchase|
|--------------|-------------- |---------------|
| A            | sushi         | 1             |
| B            | curry         | 1             |
| C            | ramen         | 1             |

/*Insights:

Customer `A` had sushi for the first time, customer `B` had curry and customer `C` had ramen.*/

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
  menu.product_name,
  COUNT(sales.product_id) AS order_count
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
GROUP BY
  menu.product_name
ORDER BY order_count DESC
LIMIT 1;

--Output:
| product_id  | product_name  | order_count  |
|-------------|---------------|--------------|
| 3           | ramen         | 8            |


 /*Insights:

The most purchased product was `ramen` as it was purchased 8 times.*/

--5. Which item was the most popular for each customer?


WITH cte_order_count AS (
  SELECT
    sales.customer_id,
    menu.product_name,
    COUNT(*) as order_count
  FROM dannys_diner.sales
  JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
  GROUP BY 
    customer_id,
    product_name
  ORDER BY
    customer_id,
    order_count DESC
),
cte_popular_rank AS (
  SELECT 
    *,
    RANK() OVER(PARTITION BY customer_id ORDER BY order_count DESC) AS rank
  FROM cte_order_count
)
SELECT * FROM cte_popular_rank
WHERE rank = 1;

--Output:

| customer_id  | product_name  | order_count  | rank  |
|--------------|---------------|--------------|-------|
| A            | ramen         | 3            | 1     |
| B            | ramen         | 2            | 1     |
| B            | curry         | 2            | 1     |
| B            | sushi         | 2            | 1     |
| C            | ramen         | 3            | 1     |


/*Insights:

The favorite dish of customer A & customer C is ramen while the favorite dishes for customer B are curry, ramen and sushi.*/

--6. Which item was purchased first by the customer after they became a member?

    WITH
        cte_first_member_order
        AS
        (
        SELECT customer_id, product_name, order_date, RANK() OVER(
        PARTITION BY customer_id
        ORDER BY order_date) as purchase
            FROM dannys_diner.sales AS s
                INNER JOIN dannys_diner.menu USING(product_id)
                LEFT JOIN dannys_diner.members AS mem  USING(customer_id) 
            WHERE s.order_date >= join_date
            ORDER BY order_date
        )
    SELECT customer_id,product_name,order_date
    FROM cte_first_member_order
    WHERE purchase=1;
--Output:

| customer_id | product_name | order_date               |
| ----------- | ------------ | ------------------------ |
| A           | curry        | 2021-01-07T00:00:00.000Z |
| B           | sushi        | 2021-01-11T00:00:00.000Z |

/*Insights:

Customer A bought curry and customer B had sushi after being a member.*/

--7. Which item was purchased just before the customer became a member?
WITH
    cte_last_order_before_member
    AS
   (
        SELECT customer_id, product_name, order_date, RANK() OVER(
    PARTITION BY customer_id
    ORDER BY order_date desc) as purchase
        FROM dannys_diner.sales AS s
            INNER JOIN dannys_diner.menu USING(product_id)
            LEFT JOIN dannys_diner.members AS mem  USING(customer_id) 
        WHERE s.order_date < join_date
        ORDER BY order_date desc
    )
SELECT customer_id,product_name,order_date
FROM cte_last_order_before_member
WHERE purchase=1;

--Output:

| customer_id  | product_name  | order_date                |
|--------------|---------------|---------------------------|
| A            | sushi         | 2021-01-01T00:00:00.000Z  |
| A            | curry         | 2021-01-01T00:00:00.000Z  |
| B            | sushi         | 2021-01-04T00:00:00.000Z  |


/*Insights:

Customer A bought sushi and curry while customer B had curry before being a member.*/

--8. What is the total items and amount spent for each member before they became a member?

WITH
    cte_spent_before_mem
    AS
   (
        SELECT customer_id, SUM(price) AS total_spent,count(s.product_id) as total_item
        FROM dannys_diner.sales AS s
            INNER JOIN dannys_diner.menu USING(product_id)
            INNER JOIN dannys_diner.members AS mem  USING(customer_id) 
        WHERE s.order_date < join_date
        GROUP BY customer_id
    )
SELECT *
FROM cte_spent_before_mem;

--Output:

| customer_id  | total_spent  | total_items  |
|--------------|--------------|--------------|
| A            | 25           | 2            |
| B            | 40           | 3            |


/*Insights:
Before becoming a member customer A spent 25$ on 2  products while customer B spent 40$ on 3 products.*/

/*9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

Case expression are really helpful in such scenarois and behave similar to if else statements So if product is sushi then we multiply price by 20 
or else multiply price by 10*/

SELECT customer_id, 
       SUM(CASE WHEN product_name = 'sushi' THEN  (price * 20)
            ELSE (price * 10) END ) AS total_points,
       COUNT(s.product_id) as total_item
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu USING(product_id)
GROUP BY customer_id;

--Output:

| customer_id | total_points | total_item |
| ----------- | ------------ | ---------- |
| A           | 860          | 6          |
| B           | 940          | 6          |
| C           | 360          | 3          |

/*Insights:

Customer A has 860 points, customer B has 940 points and customer C has 360 points.*/

/*10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**

We need a range of date  from the date customer became a member till first 6 days( 1 week) , so we use CASE with 'and` condition.*/


SELECT dannys_diner.sales.customer_id , 
SUM(CASE WHEN order_date >= join_date AND order_date <= join_date + 6  THEN price * 20  
         WHEN product_name = 'sushi' THEN price * 20  
  	ELSE  price * 10  
    END ) as points 
FROM dannys_diner.sales 
LEFT JOIN dannys_diner.menu USING (product_id) 
LEFT JOIN dannys_diner.members USING (customer_id) 
WHERE (customer_id = 'A' OR customer_id = 'B') 
AND order_date < '2021-01-31' 
GROUP BY customer_id;

--Output:

| customer_id | points       |
|-------------|--------------|
| A           | 1370         |
| B           | 820          |

/*Insights:

At the end of january, customer A would have 1370 points while customer B would have 820 points.*/

