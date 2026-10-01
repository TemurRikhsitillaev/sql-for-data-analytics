-- 1
-- SELECT product_name, units_in_stock FROM products
-- WHERE units_in_stock = 0;

-- 2
-- SELECT product_name, unit_price FROM products
-- WHERE unit_price > 50
-- ORDER BY unit_price DESC;

-- 3
-- SELECT order_id, order_date FROM orders
-- WHERE order_date >= '1998-01-01';

-- 4
-- SELECT product_name, unit_price * units_in_stock AS stock_value 
-- FROM products
-- WHERE unit_price * units_in_stock > 3000;

-- 5
-- SELECT customer_id, contact_name, city 
-- FROM customers
-- WHERE country = 'Germany' AND city IN ('Berlin', 'München');

-- 6
-- SELECT product_id, discontinued, units_in_stock 
-- FROM products
-- WHERE discontinued = 1 AND units_in_stock > 0;

-- 7
-- SELECT product_id, category_id, unit_price
-- FROM products
-- WHERE (category_id = 1 OR category_id = 2) AND unit_price < 20;
-- SELECT product_id, category_id, unit_price
-- FROM products
-- WHERE category_id = 1 OR category_id = 2 AND unit_price < 20

-- 8
-- SELECT customer_id, country 
-- FROM customers
-- WHERE country IN ('UK', 'France', 'Spain')
-- ORDER BY country;

-- 9
-- SELECT product_id, unit_price
-- FROM products
-- WHERE unit_price BETWEEN 10 AND 20;

-- 10
-- SELECT order_id, order_date
-- FROM orders
-- WHERE order_date >= '1997-12-01' AND order_date < '1998-01-01';

-- 11
-- SELECT user_id, registered_at
-- FROM users
-- WHERE registered_at >= '2025-12-01' AND registered_at < '2026-01-01';
-- SELECT user_id, registered_at
-- FROM users
-- WHERE registered_at BETWEEN '2025-12-01' AND '2025-12-31';

-- 12
-- SELECT product_name
-- FROM products
-- WHERE product_name ILIKE '%sauce%';

-- 13
-- SELECT customer_id
-- FROM customers
-- WHERE customer_id LIKE 'B%';

-- 14
-- SELECT last_name 
-- FROM employees
-- WHERE last_name LIKE '%n';

-- 15
-- SELECT customer_id, region 
-- FROM customers
-- WHERE region IS NULL;

-- 16
-- SELECT order_id, shipped_date
-- FROM orders
-- WHERE shipped_date IS NULL;

-- 17
-- SELECT user_id, acquisition_channel
-- FROM users
-- WHERE acquisition_channel <> 'organic';
-- SELECT user_id, acquisition_channel
-- FROM users
-- WHERE acquisition_channel <> 'organic' OR acquisition_channel IS NULL;

-- 18
-- SELECT event_id, user_id, event_type 
-- FROM events
-- WHERE event_type = 'add_to_cart';

-- 19
-- SELECT event_id, user_id, event_time 
-- FROM events
-- WHERE user_id = 4500
-- ORDER BY event_time;

-- 20
-- SELECT * 
-- FROM events
-- WHERE 
-- 	event_type = 'view_product' 
-- 	AND product_id IN (4, 6, 40) 
-- 	AND event_time >= '2025-01-01' AND event_time < '2025-02-01';













