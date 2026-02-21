/** 
Name: Mikkel E.T. Mortensen
Date: 21/02/26
Description: Logistics bottleneck analysis **/

WITH CategorizedOrders AS (
SELECT 
	order_id AS "Order ID",
	order_estimated_delivery_date AS ETA,
	order_delivered_customer_date AS "Delivery Date",
	julianday(strftime("%Y-%m-%d",order_delivered_customer_date)) - julianday(strftime("%Y-%m-%d", order_estimated_delivery_date)) AS Delay,
	CASE
	WHEN julianday(strftime("%Y-%m-%d",order_delivered_customer_date)) - julianday(strftime("%Y-%m-%d", order_estimated_delivery_date)) <= 0 THEN 'ON TIME'
	WHEN julianday(strftime("%Y-%m-%d",order_delivered_customer_date)) - julianday(strftime("%Y-%m-%d", order_estimated_delivery_date)) BETWEEN 1.00 AND 3.00 THEN 'DELAY'
	ELSE 'CRITICAL DELAY'
	END AS DelayType
FROM
	Orders	
WHERE 
	order_delivered_customer_date IS NOT NULL)
	
SELECT
	DelayType,
	COUNT("Order ID") AS Total_Orders
FROM 
	CategorizedOrders
GROUP BY
	DelayType
ORDER BY
	Total_Orders DESC;

/** Name: Mikkel E.T. Mortensen
Date: 21/02/26
Description: Delivery Delay Impact on Customer Satisfaction
**/

WITH CategorizedOrders AS (
SELECT 
	order_id AS "Order ID",
	order_estimated_delivery_date AS ETA,
	order_delivered_customer_date AS "Delivery Date",
	julianday(strftime("%Y-%m-%d",order_delivered_customer_date)) - julianday(strftime("%Y-%m-%d", order_estimated_delivery_date)) AS Delay,
	CASE
	WHEN julianday(strftime("%Y-%m-%d",order_delivered_customer_date)) - julianday(strftime("%Y-%m-%d", order_estimated_delivery_date)) <= 0 THEN 'ON TIME'
	WHEN julianday(strftime("%Y-%m-%d",order_delivered_customer_date)) - julianday(strftime("%Y-%m-%d", order_estimated_delivery_date)) BETWEEN 1.00 AND 3.00 THEN 'DELAY'
	ELSE 'CRITICAL DELAY'
	END AS DelayType
FROM
	Orders	
WHERE 
	order_delivered_customer_date IS NOT NULL)
	
SELECT
	c.DelayType,
	COUNT("Order ID") AS Total_Orders,
	ROUND(AVG(r.review_score), 2) AS Avg_Review_Score
FROM 
	CategorizedOrders AS c
INNER JOIN
	Reviews AS r
ON 
	c."Order ID" = r.order_id
GROUP BY
	DelayType
ORDER BY
	Avg_Review_Score DESC


/** 
Name: Mikkel E.T. Mortensen
Date: 21/02/26
Description: Top 10 worst vendors based on delays (min 10 delays) **/

WITH CategorizedOrders AS (
SELECT 
	order_id AS "Order ID",
	order_estimated_delivery_date AS ETA,
	order_delivered_customer_date AS "Delivery Date",
	julianday(strftime("%Y-%m-%d",order_delivered_customer_date)) - julianday(strftime("%Y-%m-%d", order_estimated_delivery_date)) AS Delay,
	CASE
	WHEN julianday(strftime("%Y-%m-%d",order_delivered_customer_date)) - julianday(strftime("%Y-%m-%d", order_estimated_delivery_date)) <= 0 THEN 'ON TIME'
	WHEN julianday(strftime("%Y-%m-%d",order_delivered_customer_date)) - julianday(strftime("%Y-%m-%d", order_estimated_delivery_date)) BETWEEN 1.00 AND 3.00 THEN 'DELAY'
	ELSE 'CRITICAL DELAY'
	END AS DelayType
FROM
	Orders	
WHERE 
	order_delivered_customer_date IS NOT NULL)

SELECT 
	i.seller_id AS Seller,
	c.DelayType,
	COUNT(c."Order ID") AS Total_Critical_Delays
	
FROM
	CategorizedOrders AS c
INNER JOIN 
	Items AS i
ON 
	c."Order ID" = i.order_id
WHERE 
	DelayType = 'CRITICAL DELAY'
GROUP BY
	i.seller_id
HAVING
	Total_Critical_Delays > 10
ORDER BY
	Total_Critical_Delays DESC
LIMIT 10

/** 
Name: Mikkel E.T. Mortensen
Date: 21/02/26
Description: Retention Analysis **/


WITH Retention AS
(SELECT
	c.customer_unique_id AS CustomerID,
	o.customer_id AS CustomerOrder,
	o.order_id AS "Order",
	strftime("%Y-%m-%d",o.order_purchase_timestamp) AS CurrentOrder,
	LAG(strftime("%Y-%m-%d",o.order_purchase_timestamp)) OVER(PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp ASC) AS PreviousOrder
FROM 
	Orders AS o
INNER JOIN
	Customers AS c
ON 
	o.customer_id = c.customer_id),
AverageRetention AS

(SELECT 
	r.CustomerID,
	r."Order",
	r.CurrentOrder,
	r.PreviousOrder,
	julianday(r.CurrentOrder) - julianday(r.PreviousOrder) AS DaysBetweenOrders
FROM 
	Retention AS r
WHERE
	r.PreviousOrder IS NOT NULL)

SELECT
	round(AVG(DaysBetweenOrders),2) AS [Average days between orders]
FROM 
	AverageRetention


	