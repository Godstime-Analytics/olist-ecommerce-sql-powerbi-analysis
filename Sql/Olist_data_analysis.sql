--========================================
--OLIST E-COMMERCE SALES ANALYSIS PROJECT
--========================================
CREATE TABLE customers (
			customer_id VARCHAR PRIMARY KEY,
			customer_unique_id VARCHAR,
			customer_zip_code_prefix INT,
			customer_city VARCHAR,
			customer_state VARCHAR
);

CREATE TABLE orders (
			order_id VARCHAR PRIMARY KEY,
			customer_id VARCHAR,
			order_status VARCHAR,
			order_purchase_timestamp TIMESTAMP,
			order_approved_at TIMESTAMP,
			order_delivered_carrier_date TIMESTAMP,
			order_delivered_customer_date TIMESTAMP,
			order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE order_items (
			order_id VARCHAR,
			order_item_id INT,
			product_id VARCHAR,
			seller_id VARCHAR,
			shipping_limit_date TIMESTAMP,
			price NUMERIC,
			freight_value NUMERIC
);

CREATE TABLE order_payments (
			order_id VARCHAR,
			payment_sequential INT,
			payment_type VARCHAR,
			payment_installments INT,
			payment_value NUMERIC
);

CREATE TABLE geolocation (
			geolocation_zip_code_prefix	INT,
			geolocation_lat	DOUBLE PRECISION,
			geolocation_lng DOUBLE PRECISION,
			geolocation_city VARCHAR,
			geolocation_state VARCHAR
);

CREATE TABLE order_review (
			review_id VARCHAR,
			order_id VARCHAR,
			review_score INT,
			review_comment_title VARCHAR,
			review_comment_message VARCHAR,
			review_creation_date TIMESTAMP,	
			review_answer_timestamp TIMESTAMP	
);

CREATE TABLE products (
			product_id VARCHAR,
			product_category_name VARCHAR,
			product_name_lenght INT,
			product_description_lenght INT,
			product_photos_qty INT,
			product_weight_g INT,
			product_length_cm INT,
			product_height_cm INT,
			product_width_cm INT
);

CREATE TABLE sellers (
			seller_id VARCHAR PRIMARY KEY,
			seller_zip_code_prefix INT,
			seller_city VARCHAR,
			seller_state VARCHAR
);

CREATE TABLE product_category_name_translation (
			product_category_name VARCHAR,
			product_category_name_english VARCHAR
);

-- Created Constraints
ALTER TABLE order_items
ADD CONSTRAINT pk_order_items
PRIMARY KEY (order_id, order_item_id);

ALTER TABLE order_payments
ADD CONSTRAINT pk_order_payments
PRIMARY KEY (order_id, payment_sequential);

ALTER TABLE order_review
ADD CONSTRAINT pk_order_review
PRIMARY KEY (review_id, order_id);

ALTER TABLE products
ADD CONSTRAINT pk_products
PRIMARY KEY (product_id);

--========
--Analysis
--========

-- Check for Duplicates through all tables
-- No true duplicates present in all tables

--In Customers Table
SELECT *
FROM (SELECT *,
		ROW_NUMBER() OVER (PARTITION BY customer_id, customer_unique_id, 
								customer_zip_code_prefix, customer_city,
								customer_state
							ORDER BY customer_id) AS rn
	  FROM customers
)t
WHERE rn > 1;

--In Order Payment Table
SELECT *
FROM (SELECT *,
		ROW_NUMBER() OVER (PARTITION BY order_id, payment_sequential, payment_type, 
										payment_installments, payment_value 
						 	ORDER BY order_id) AS rn
		FROM order_payments
)t
WHERE rn > 1;

--In Order Review Table
SELECT *
FROM (SELECT *,
		ROW_NUMBER() OVER (PARTITION BY review_id, order_id, review_score, review_comment_title,
										review_comment_message, review_creation_date,	
										review_answer_timestamp
			ORDER BY order_id) AS rn
		FROM order_review
)t
WHERE rn > 1;

--In Orders Table
SELECT *
FROM (SELECT *,
		ROW_NUMBER() OVER (PARTITION BY order_id, customer_id, order_status, order_purchase_timestamp,
										order_approved_at, order_delivered_carrier_date,
										order_delivered_customer_date, order_estimated_delivery_date 
			ORDER BY order_id) AS rn
		FROM orders
)t
WHERE rn > 1;

--In Products Table
SELECT *
FROM (SELECT *,
		ROW_NUMBER() OVER (PARTITION BY product_id, product_category_name, product_name_lenght,
										product_description_lenght, product_photos_qty,
										product_weight_g, product_length_cm, product_height_cm,
										product_width_cm 
			ORDER BY product_id) AS rn
		FROM products
)t
WHERE rn > 1;

--In Sellers Table
SELECT *
FROM (SELECT *,
		ROW_NUMBER() OVER (PARTITION BY seller_id, seller_zip_code_prefix,
										seller_city, seller_state 
							ORDER BY seller_id) AS rn
		FROM sellers
)t
WHERE rn > 1;

--===No true Duplicate present===

-- TOTAL REVENUE
-- Insight: Measures total sales performance across the business
SELECT SUM(price) AS Total_Revenue
FROM order_items;

--TOTAL BUSINESS REVENUE
-- Measures overall business earnings from all completed transactions 
SELECT SUM(price + freight_value) AS Total_Business_Revenue
FROM order_items;

-- TOTAL ORDERS
-- Insight: Tracks total number of orders placed
SELECT count(*)
FROM orders;

-- MONTHLY REVENUE TREND
-- Insight: Revenue shows consistent growth over time, peaking in 2017
SELECT DATE_TRUNC('month', o.order_purchase_timestamp) AS month, SUM(oi.price + oi.freight_value)
FROM orders o
JOIN order_items oi
on oi.order_id = o.order_id
GROUP BY month
ORDER BY month;


-- TOP 5 CUSTOMERS RANKING
-- Insight: Ranking customers based on total spend using window functions
SELECT *
FROM (
		SELECT c.customer_unique_id, SUM(oi.price + oi.freight_value) As total_spent,
			RANK() OVER (ORDER BY SUM(oi.price + oi.freight_value) DESC) AS customer_rank
		FROM customers c
		JOIN orders o
			ON o.customer_id = c.customer_id
		JOIN order_items oi
			on oi.order_id = o.order_id
		GROUP BY c.customer_unique_id) ranked_customers
WHERE customer_rank <= 5;

--REVENUE BY CATEGORY
--The beleza_saude category generates the highest total revenue, making it the primary revenue driver
SELECT p.product_category_name, SUM(oi.price) AS revenue
FROM products p
JOIN order_items oi
	ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY revenue DESC;

-- TOP PRODUCTS 
-- highest performing products are concentrated within the health_beauty category
-- indicating strong category dominance
SELECT  p.product_id, pt.product_category_name_english, SUM(oi.price) AS revenue,
		RANK() OVER (ORDER BY SUM(oi.price) DESC) AS product_rank
FROM products p
JOIN product_category_name_translation pt
	ON pt.product_category_name = p.product_category_name
JOIN order_items oi
	ON p.product_id = oi.product_id
GROUP BY p.product_id, pt.product_category_name_english;

-- ORDERS BY STATE
-- Insight: São Paulo (SP) has the highest order volume
SELECT c.customer_state, count(o.order_id) no_of_orders
FROM customers c
JOIN orders o
	ON c.customer_id = o.customer_id
GROUP by c.customer_state
ORDER BY no_of_orders DESC;

-- TOP SELLERS BY REVENUE
-- Insight: A small group of sellers dominate marketplace revenue
SELECT  s.seller_id, s.seller_state, SUM(oi.price + oi.freight_value) AS revenue,
		DENSE_RANK() OVER (ORDER BY SUM(oi.price + oi.freight_value) DESC) seller_rank
	FROM sellers s
	JOIN order_items oi
		ON oi.seller_id = s.seller_id
	GROUP BY s.seller_id, s.seller_state;

-- MONTHLY ORDER VOLUME
-- Insight: Order volume increases over time, reflecting business growth
SELECT 	DATE_TRUNC('month', order_purchase_timestamp) AS month, 
		count(order_id) no_of_orders
FROM orders
GROUP BY month
ORDER BY month;

-- MONTH-OVER-MONTH (MoM) GROWTH
-- Insight: Tracks revenue growth rate between consecutive months
WITH monthly_sales AS (
						SELECT DATE_TRUNC('month', o.order_purchase_timestamp) AS month, 
						SUM(oi.price + oi.freight_value) AS sales
						FROM orders o
						JOIN order_items oi
							ON oi.order_id = o.order_id
						GROUP BY month
)
SELECT month, sales, LAG(sales) OVER (ORDER BY month) AS prev_month,
		(sales - LAG(sales) OVER (ORDER BY month))::float / 
		LAG(sales) OVER (ORDER BY month) AS mom_growth
FROM monthly_sales
ORDER BY month;





-- MASTER DATASET CREATION
-- Combines orders, customers, products, sellers, and payments
-- Insight: Builds a unified dataset for business analysis and reporting
SELECT 	o.order_id, oi.order_item_id, o.order_status, o.order_purchase_timestamp,
		o.order_approved_at,o.order_delivered_customer_date, c.customer_id,
		c.customer_unique_id, c.customer_city, c.customer_state, c.customer_zip_code_prefix,
		p.product_id, pt.product_category_name_english, s.seller_id, s.seller_city, s.seller_state,
		s.seller_zip_code_prefix, oi.price, oi.freight_value,
		(oi.price + oi.freight_value) as revenue
	
FROM order_items oi
JOIN orders o
	ON o.order_id = oi.order_id
JOIN customers c
	ON c.customer_id = o.customer_id
JOIN products p
	ON p.product_id = oi.product_id
JOIN product_category_name_translation pt
	ON pt.product_category_name = p.product_category_name
JOIN sellers s
	ON s.seller_id = oi.seller_id;








