-- 1. Товары с названиями категорий: product_name, category_name, unit_price. Только те, что продаются, по алфавиту.

-- SELECT p.product_name, c.category_name, p.unit_price
-- FROM products AS p
-- JOIN categories AS c ON p.category_id = c.category_id
-- WHERE p.discontinued = 0
-- ORDER BY p.product_name;


-- 2. Заказы с названиями компаний-клиентов: order_id, order_date, company_name, country. Топ-10 самых свежих.

-- SELECT o.order_id, o.order_date, c.company_name, c.country
-- FROM orders AS o
-- JOIN customers AS c ON o.customer_id = c.customer_id
-- ORDER BY o.order_date DESC
-- LIMIT 10;


-- 3. Заказы с именем сотрудника, который их оформил: order_id, order_date и Фамилия Имя одной колонкой. 
-- Первые 20 по дате.

-- SELECT o.order_id, o.order_date, e.last_name || ' ' || e.first_name AS "Фамилия Имя"
-- FROM orders AS o
-- JOIN employees AS e ON o.employee_id = e.employee_id
-- ORDER BY o.order_date
-- LIMIT 20;


-- 4. Позиции заказа 10248: название товара, количество, цена, сумма позиции.

-- SELECT p.product_name, 
-- 	od.quantity, 
-- 	od.unit_price, 
-- 	ROUND(od.unit_price::numeric * od.quantity * (1 - od.discount::numeric), 2) AS total_price
-- FROM order_details AS od
-- 	JOIN products AS p ON od.product_id = p.product_id
-- WHERE od.order_id = 10248


-- 5. Товары с названием категории и названием поставщика (suppliers.company_name). Только категория Beverages.

-- SELECT p.product_name, c.category_name, s.company_name AS supplier_name
-- FROM products AS p
-- JOIN categories AS c ON p.category_id = c.category_id
-- JOIN suppliers AS s ON p.supplier_id = s.supplier_id
-- WHERE c.category_name = 'Beverages';


-- 6. Все клиенты и количество их заказов. Клиенты без заказов должны быть с нулём. 
-- Сортировка по количеству по убыванию.

-- SELECT c.company_name, COUNT(o.order_id) AS total_orders
-- FROM customers AS c
-- 	LEFT JOIN orders AS o ON c.customer_id = o.customer_id
-- GROUP BY c.company_name
-- ORDER BY total_orders DESC;


-- 7. Клиенты, которые ни разу ничего не заказывали.

-- SELECT c.company_name
-- FROM customers AS c
-- LEFT JOIN orders AS o ON c.customer_id = o.customer_id
-- WHERE o.order_id IS NULL;


-- 8. Товары, которые ни разу не продавались (нет строк в order_details).

-- SELECT p.product_name
-- FROM products AS p
-- LEFT JOIN order_details AS od ON p.product_id = od.product_id
-- WHERE od.order_id IS NULL;


-- 9. Все категории и количество товаров в каждой, включая категории без товаров.

-- SELECT c.category_id, COUNT(p.product_id) AS products_count
-- FROM categories AS c
-- LEFT JOIN products AS p ON c.category_id = p.category_id
-- GROUP BY c.category_id


-- 10. Пользователи из users с количеством их событий, включая тех, у кого событий нет. 
-- Топ-20 по количеству событий.

-- SELECT u.user_id, COUNT(e.event_id) as total_events
-- FROM users AS u
-- LEFT JOIN events AS e ON u.user_id = e.user_id
-- GROUP BY u.user_id
-- ORDER BY total_events DESC
-- LIMIT 20;


-- 11. Выручка по категориям: category_name, 
-- выручка (unit_price * quantity * (1 - od.discount), округли),
-- количество разных заказов. От большей выручки.

-- SELECT c.category_name, 
-- 	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric), 2) AS revenue,
-- 	COUNT(DISTINCT od.order_id) AS unique_orders
-- FROM categories AS c
-- 	JOIN products AS p ON c.category_id = p.category_id
-- 	JOIN order_details AS od ON od.product_id = p.product_id
-- GROUP BY c.category_name
-- ORDER BY revenue DESC;


-- 12. Топ-10 товаров по выручке: название, категория, выручка.

-- SELECT p.product_name, 
-- 	c.category_name,
-- 	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric), 2) AS revenue
-- FROM products AS p
-- 	JOIN categories AS c ON p.category_id = c.category_id
-- 	JOIN order_details AS od ON od.product_id = p.product_id
-- GROUP BY p.product_name, c.category_name
-- ORDER BY revenue DESC
-- LIMIT 10;


-- 13. Топ-10 клиентов по сумме заказов: название компании, страна, сумма, количество заказов.

-- SELECT c.company_name,
-- 	c.country,
-- 	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric), 2) AS total_spent,
-- 	COUNT(DISTINCT o.order_id) AS orders_count
-- FROM customers AS c
-- 	LEFT JOIN orders AS o ON c.customer_id = o.customer_id
-- 	LEFT JOIN order_details AS od ON o.order_id = od.order_id
-- GROUP BY c.company_name, c.country
-- ORDER BY total_spent DESC NULLS LAST
-- LIMIT 10;


-- 14. Сотрудники и количество оформленных ими заказов: Фамилия Имя, количество. От большего.

-- SELECT e.last_name || ' ' || e.first_name AS "Fullname",
-- 	COUNT(DISTINCT o.order_id) AS total_orders
-- FROM employees AS e
-- 	LEFT JOIN orders AS o ON e.employee_id = o.employee_id
-- GROUP BY e.last_name || ' ' || e.first_name 
-- ORDER BY total_orders DESC;


-- 15. Выручка по странам клиентов за 1997 год: страна, выручка, количество клиентов.

-- SELECT c.country,
-- 	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric), 2) AS revenue,
-- 	COUNT(DISTINCT c.customer_id) AS customers_count
-- FROM customers AS c
-- 	LEFT JOIN orders AS o ON c.customer_id = o.customer_id
-- 	LEFT JOIN order_details AS od ON o.order_id = od.order_id
-- WHERE o.order_date >= '1997-01-01' AND o.order_date < '1998-01-01'
-- GROUP BY c.country;


-- 16. Для каждого заказа 1998 года: order_id, название компании, страна доставки, сумма заказа. 
-- Топ-10 по сумме.

-- SELECT o.order_id, 
-- 	c.company_name, 
-- 	o.ship_country,
-- 	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric), 2) AS order_price
-- FROM orders AS o
-- 	JOIN customers AS c ON o.customer_id = c.customer_id
-- 	JOIN order_details AS od ON o.order_id = od.order_id
-- WHERE o.order_date >= '1998-01-01' AND o.order_date < '1999-01-01'
-- GROUP BY o.order_id, c.company_name, o.ship_country
-- ORDER BY order_price DESC
-- LIMIT 10;

-- 17. Какие товары покупали клиенты из Германии: название товара, суммарное количество. Топ-10.

-- SELECT p.product_name,
-- 	SUM(od.quantity) AS total_count
-- FROM products AS p
-- 	JOIN order_details AS od ON p.product_id = od.product_id
-- 	JOIN orders AS o ON od.order_id = o.order_id
-- 	JOIN customers AS c ON o.customer_id = c.customer_id
-- WHERE c.country = 'Germany'
-- GROUP BY p.product_name
-- ORDER BY total_count DESC
-- LIMIT 10;


-- 18. Для каждой категории: название, 
-- количество товаров, количество разных заказов, 
-- в которых эти товары встречались.

-- SELECT c.category_name, 
-- 	COUNT(DISTINCT p.product_id) AS products_count,
-- 	COUNT(DISTINCT od.order_id) AS orders_count
-- FROM categories AS c
-- 	JOIN products AS p ON c.category_id = p.category_id
-- 	LEFT JOIN order_details AS od ON p.product_id = od.product_id
-- GROUP BY c.category_name;


-- 19. Топ-10 просматриваемых товаров: product_name, количество просмотров, количество добавлений в корзину. 
-- Подсказка: пока можно сделать двумя отдельными запросами, одним научимся позже.

-- SELECT p.product_name, COUNT(e.event_id) AS views_count
-- FROM products AS p
-- 	LEFT JOIN events AS e ON p.product_id = e.product_id
-- WHERE event_type = 'view_product'
-- GROUP BY p.product_name, p.product_id
-- ORDER BY views_count DESC
-- LIMIT 10;

-- SELECT p.product_name, COUNT(e.event_id) AS views_count
-- FROM products AS p
-- 	JOIN events AS e ON p.product_id = e.product_id
-- WHERE event_type = 'add_to_cart'
-- GROUP BY p.product_name, p.product_id
-- ORDER BY views_count DESC
-- LIMIT 10;


-- 20. Количество событий по странам пользователей: страна, количество событий, количество разных пользователей. 
-- От большего количества событий.

-- SELECT u.country, 
-- 	COUNT(e.event_id) AS events_count,
-- 	COUNT(DISTINCT u.user_id) AS users_count
-- FROM users AS u
-- 	LEFT JOIN events AS e ON u.user_id = e.user_id
-- GROUP BY u.country
-- ORDER BY events_count DESC;














