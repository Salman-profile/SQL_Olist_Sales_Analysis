
--- What are the total number of orders?

SELECT
	COUNT(*) AS Orders_Count
FROM
	orders;
	

--- What are the total number of monthly orders?

SELECT
	strftime('%Y-%m', order_purchase_timestamp) 
	AS "Month",
	COUNT(*) as Total_Orders
FROM 
	orders
GROUP BY
	"Month"
ORDER BY 
	"Month" ;
	

--- What is the breakup of order's status?

SELECT
	order_status,
	COUNT(*) as Total_Orders
FROM 
	orders
GROUP BY
	order_status
ORDER BY 
	Total_Orders DESC;


--- which are the top-10 sold items?
			
SELECT 
	pct.product_category_name_english,
	COUNT(*) as Orders_Count
FROM 
	order_items oi
JOIN 
	products p
	ON oi.product_id = p.product_id
JOIN 
	product_category_name_translation pct
	ON p.product_category_name = pct.product_category_name
GROUP BY
	pct.product_category_name_english
ORDER BY 
	Orders_Count DESC
LIMIT 10;


--- which are the top ordering cities?

SELECT 
	c.customer_city,
	COUNT(*) as Total_Orders
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY c.customer_city
ORDER by COUNT(*) DESC;


--- List shipment delayed orders

SELECT
	COUNT(*) as Late_Shipment_Count
FROM
	(
	SELECT
		order_id,
		order_estimated_delivery_date,
		order_delivered_customer_date,
		(STRFTIME('%s', order_estimated_delivery_date) - STRFTIME('%s', order_delivered_customer_date)) / (60 * 60) AS Shipment_Delyed_hours

	FROM orders
	WHERE order_estimated_delivery_date IS NOT NULL AND order_delivered_customer_date IS NOT NULL and Shipment_Delyed_hours < -0
	ORDER BY Shipment_Delyed_hours 
	)TB;
	

---- Top 10 Prduct categories with highest number of poor rating review?

SELECT
	p.product_category_name,
	orv.review_score,
	count(*) as Total_Review
FROM
	order_reviews orv
JOIN 
	order_items oi
ON orv.order_id = oi.order_id
JOIN 
	products p
ON oi.product_id = p.product_id
WHERE 
	p.product_category_name IS NOT NULL 
	AND orv.review_score = 1
GROUP BY 
	p.product_category_name,
	orv.review_score
ORDER BY Total_Review DESC
LIMIT 10;


--- what is monthly orders delivery ratio?

SELECT 
	strftime('%Y-%m', order_purchase_timestamp) AS order_month,
	COUNT(*) AS total_orders,
	COUNT(CASE WHEN order_status = 'delivered' 
	THEN 1 ELSE NULL END) AS delivered_orders,
	ROUND((100.00 * COUNT(CASE WHEN order_status = 'delivered' 
	THEN 1 ELSE NULL END))/COUNT(*),2) || '%' AS "order_delivery_ratio"
	
FROM
	orders
GROUP BY order_month
ORDER BY order_month;


--- What is monthly commulative payment for whole period

WITH MONTHLY_PAYMENT AS
	(
	SELECT 
		strftime('%Y-%m', o.order_purchase_timestamp) AS "Month",
		sum(op.payment_value) as Payment
	FROM 
		orders o
	JOIN 
		order_payments op
	ON o.order_id = op.order_id
	GROUP BY "Month"
	ORDER BY "Month"
)

SELECT
	Month,
	Payment,
	SUM(Payment) OVER (ORDER BY Month) AS Cumulative_Payment
 
FROM 
	MONTHLY_PAYMENT;
	

--Which are the monthly top selling products for each category

WITH MONTHLY_PRODUCTS AS
	(
	SELECT
		strftime('%Y-%m', o.order_purchase_timestamp) AS "Month",
		p.product_category_name AS "Category",
		COUNT(*) as Total_Orders
	FROM 
		orders o
	JOIN
		order_items oi
	ON o.order_id = oi.order_id
	JOIN 
		products p
	ON oi.product_id = p.product_id
	GROUP BY
		"Month",p.product_category_name
	),
CTE_RANK AS 
	(
	SELECT 
		Month,
		Category,
		Total_Orders,
		DENSE_RANK() OVER (PARTITION BY Month ORDER BY Total_Orders DESC) AS SalesRank
		FROM MONTHLY_PRODUCTS
	)
SELECT * 
FROM CTE_RANK
WHERE SalesRank =1;