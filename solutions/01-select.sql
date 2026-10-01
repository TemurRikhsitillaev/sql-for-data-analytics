-- 1
-- SELECT first_name, last_name, title FROM employees;

-- 2
-- SELECT * FROM categories;
-- SELECT category_name FROM categories;

-- 3
-- SELECT company_name, country, city FROM suppliers;

-- 4
-- SELECT product_name, ROUND((unit_price * 0.85)::numeric, 2) AS sale_price FROM products;

-- 5
-- SELECT last_name || ', ' || first_name AS "Сотрудник" FROM employees ORDER BY last_name;

-- 6
-- SELECT order_id, product_id, unit_price * quantity * (1 - discount) AS line_total FROM order_details;

-- 7
-- SELECT units_in_stock / reorder_level, (units_in_stock::numeric / reorder_level) 
-- FROM products
-- WHERE reorder_level <> 0;

-- 8
-- SELECT product_name AS "Название товара", unit_price as "Цена, $" FROM products;

-- 9
-- SELECT product_name, 'Northwind''s catalog' AS "Источник" FROM products;

-- 10
-- SELECT unit_price AS 'Цена' FROM products; -- потому что '' изпользуются для значений
-- SELECT "Product_Name" FROM products; -- идёт сравнение по букве и регистр важен

-- 11
-- SELECT DISTINCT ship_city FROM orders ORDER BY ship_city;

-- 12
-- SELECT DISTINCT country, city FROM customers ORDER BY country, city;

-- 13
-- SELECT DISTINCT title FROM employees;

-- 14
-- SELECT company_name, country, region FROM customers ORDER BY region;
-- SELECT company_name, country, region FROM customers ORDER BY region DESC;
-- SELECT company_name, country, region FROM customers ORDER BY region DESC NULLS LAST;

-- 15
-- SELECT order_id, order_date, shipped_date FROM orders ORDER BY shipped_date DESC NULLS LAST;

-- 16
-- SELECT product_name, category_id, unit_price FROM products ORDER BY category_id, unit_price DESC;

-- 17
-- SELECT product_name, unit_price FROM products ORDER BY unit_price LIMIT 3;

-- 18
-- SELECT order_id, customer_id, order_date 
-- FROM orders 
-- ORDER BY order_date DESC, order_id DESC LIMIT 10;

-- 19
-- SELECT * FROM products ORDER BY product_name LIMIT 10 OFFSET 10 * (3 - 1);


-- 20
-- SELECT * FROM orders ORDER BY freight DESC LIMIT 5 OFFSET 1;

-- 21
-- SELECT DISTINCT ON (ship_country) ship_country, order_id, order_date
-- FROM orders
-- ORDER BY ship_country, order_date DESC, order_id DESC;

-- 22
-- SELECT DISTINCT ON (category_id) category_id, product_name, unit_price FROM products
-- 	ORDER BY category_id, unit_price DESC;

-- 23
-- SELECT * FROM users LIMIT 20;
-- SELECT * FROM events LIMIT 20;













	