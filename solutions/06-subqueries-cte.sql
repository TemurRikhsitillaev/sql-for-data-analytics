-- 1. Товары, которые дороже средней цены по всей таблице. Выведи название, цену и разницу со средней.

-- SELECT product_name,
-- 	unit_price,
-- 	ROUND(unit_price::numeric - (SELECT AVG(unit_price) FROM products)::numeric, 2) AS difference
-- FROM products
-- WHERE unit_price > (SELECT AVG(unit_price) FROM products);


-- 2. Клиенты, которые ни разу ничего не заказывали, через NOT EXISTS.
-- Сравни результат с тем, что даёт NOT IN, и объясни разницу, если она есть.

-- SELECT customer_id, company_name
-- FROM customers AS c
-- WHERE NOT EXISTS (SELECT 1 FROM orders AS o WHERE o.customer_id = c.customer_id);

-- SELECT customer_id, company_name
-- FROM customers AS c
-- WHERE customer_id NOT IN (SELECT customer_id FROM orders);

-- Ответ у них одиннаковый, но NOT EXISTS проверяет на NULL, а NOT IN нет


-- 3. Заказы за последние 60 дней от максимальной даты в базе: order_id, дата, страна доставки.

-- SELECT order_id, order_date, ship_country
-- FROM orders
-- WHERE order_date >= (SELECT MAX(order_date) FROM orders) - 60;


-- 4. Товары, которые покупали клиенты из Германии,
-- через IN с подзапросом (без джойна на customers во внешнем запросе).

-- SELECT DISTINCT product_id
-- FROM order_details
-- WHERE order_id IN (
-- 	SELECT order_id
-- 	FROM orders
-- 	WHERE customer_id IN (SELECT customer_id FROM customers WHERE country = 'Germany')
-- );


-- 5. Средняя, минимальная и максимальная сумма заказа по всей базе.
-- Одна строка в результате.

-- SELECT ROUND(AVG(total_price), 2) AS avg_order_price,
-- 	ROUND(MIN(total_price), 2) AS min_order_price,
-- 	ROUND(MAX(total_price), 2) AS max_order_price
-- FROM (
-- 	SELECT COALESCE(SUM(unit_price::numeric * quantity * (1 - discount)::numeric), 0) AS total_price
-- 	FROM order_details
-- 	GROUP BY order_id
-- ) AS orders_by_total_price;


-- 6. Среднее количество позиций в заказе и среднее количество единиц товара в заказе.

-- SELECT ROUND(AVG(products), 2) AS avg_products_per_order,
-- 	ROUND(AVG(units), 2) AS avg_units_per_order
-- FROM (
-- 	SELECT order_id, COUNT(product_id) AS products, SUM(quantity) AS units
-- 	FROM order_details
-- 	GROUP BY order_id
-- );


-- 7. Распределение клиентов по количеству заказов:
-- сколько клиентов сделали 1–5 заказов, 6–10, больше 10.
-- Три строки или три колонки, на твой выбор.

-- SELECT COUNT(*) FILTER (WHERE orders_count < 6) AS from_1_to_5,
-- 	COUNT(*) FILTER (WHERE orders_count BETWEEN 6 AND 10) AS from_6_to_10,
-- 	COUNT(*) FILTER (WHERE orders_count > 10) AS from_10
-- FROM (
-- 	SELECT customer_id, COUNT(*) AS orders_count
-- 	FROM orders
-- 	GROUP BY customer_id
-- )


-- 8. Отчёт по категориям за два года через CTE.
-- Для каждой категории в одной строке: название,
-- выручка за 1997, выручка за 1998,
-- прирост в процентах ((1998 − 1997) / 1997 × 100, округли до 1 знака, защити от деления на ноль)
-- и оценка динамики (рост, если прирост больше 0, падение, если меньше, без изменений, если ровно 0).
-- Сортировка по приросту по убыванию, NULL в конец.
-- Требование: в CTE посчитать две выручки, во внешнем запросе — прирост и оценку.
-- Формула выручки должна встретиться ровно два раза (по разу на год), а не шесть, как было.

-- WITH categories_rev_1997_1998 AS (
-- 	SELECT c.category_id, c.category_name,
-- 		SUM(od.unit_price * od.quantity * (1 - od.discount)) FILTER (WHERE o.order_date >= '1997-01-01' AND o.order_date < '1998-01-01') AS rev_1997,
-- 		SUM(od.unit_price * od.quantity * (1 - od.discount)) FILTER (WHERE o.order_date >= '1998-01-01' AND o.order_date < '1999-01-01') AS rev_1998
-- 	FROM categories AS c
-- 		JOIN products AS p ON p.category_id = c.category_id
-- 		JOIN order_details AS od ON od.product_id = p.product_id
-- 		JOIN orders AS o ON o.order_id = od.order_id
-- 	WHERE o.order_date >= '1997-01-01' AND o.order_date < '1999-01-01'
-- 	GROUP BY c.category_id, c.category_name
-- )

-- SELECT category_name,
-- 	ROUND(rev_1997::numeric, 2) AS rev_1997,
-- 	ROUND(rev_1998::numeric, 2) AS rev_1998,
-- 	ROUND((rev_1998 - rev_1997)::numeric / NULLIF(rev_1997, 0)::numeric * 100.0, 1) AS growth_pct,
-- 	CASE
-- 		WHEN rev_1998 > rev_1997 THEN 'рост'
-- 		WHEN rev_1998 < rev_1997 THEN 'падение'
-- 		ELSE 'без изменений'
-- 	END AS trend
-- FROM categories_rev_1997_1998
-- ORDER BY growth_pct DESC NULLS LAST;


-- 9. Топ-10 товаров по выручке с долей каждого в общей выручке в процентах.
-- Общую выручку посчитай в отдельном CTE.

-- WITH products_revenue AS (
-- 	SELECT product_id,
-- 		SUM(unit_price * quantity * (1 - discount)) AS revenue
-- 	FROM order_details
-- 	GROUP BY product_id
-- )

-- SELECT product_id, ROUND(revenue::numeric, 2) AS revenue,
-- 	ROUND(revenue::numeric / (SELECT SUM(revenue) FROM products_revenue)::numeric * 100.0, 2) AS percentage_from_total_revenue
-- FROM products_revenue
-- ORDER BY revenue DESC
-- LIMIT 10;


-- 10. По каждому месяцу 1997 года: выручка, количество заказов,
-- средний чек и доля месяца в годовой выручке в процентах. Используй два CTE.

-- WITH orders_1997 AS (
-- 	SELECT o.order_id,
-- 		EXTRACT(MONTH FROM o.order_date) AS month,
-- 		SUM(unit_price * quantity * (1 - discount)) AS order_price
-- 	FROM orders AS o
-- 		JOIN order_details AS od ON od.order_id = o.order_id
-- 	WHERE o.order_date >= '1997-01-01' AND o.order_date < '1998-01-01'
-- 	GROUP BY o.order_id, EXTRACT(MONTH FROM o.order_date)
-- ),
-- orders_1_1997 AS (
-- 	SELECT month,
-- 		COUNT(*) AS orders_count,
-- 		SUM(order_price) AS revenue
-- 	FROM orders_1997
-- 	GROUP BY month
-- )

-- SELECT month,
-- 	orders_count,
-- 	ROUND(revenue::numeric, 2) AS revenue,
-- 	ROUND(revenue::numeric / orders_count, 2) AS avg_check,
-- 	ROUND(revenue::numeric / (SELECT SUM(revenue) FROM orders_1_1997)::numeric * 100, 2) AS percentage_from_total_revenue
-- FROM orders_1_1997
-- ORDER BY month;


-- 11. Клиенты, у которых средний чек выше общего среднего чека по всем клиентам.
-- Выведи название, средний чек клиента, общий средний и разницу.
-- Сортировка по разнице по убыванию.

-- WITH smth AS (
-- 	SELECT c.customer_id, c.company_name, o.order_id,
-- 		SUM(od.unit_price * od.quantity * (1 - od.discount)) AS receipt
-- 	FROM customers AS c
-- 		JOIN orders AS o ON c.customer_id = o.customer_id
-- 		JOIN order_details AS od ON o.order_id = od.order_id
-- 	GROUP BY c.customer_id, c.company_name, o.order_id
-- ),
-- smth2 AS (
-- 	SELECT customer_id, company_name,
-- 		COUNT(*) AS orders_count,
-- 		AVG(receipt) AS avg_receipt
-- 	FROM smth
-- 	GROUP BY customer_id, company_name
-- ),
-- smth3 AS (SELECT AVG(avg_receipt) AS avg_total_receipt FROM smth2)

-- SELECT company_name,
-- 	ROUND(avg_receipt::numeric, 2) AS avg_receipt,
-- 	ROUND(avg_total_receipt::numeric, 2) AS avg_total_receipt,
-- 	ROUND(avg_receipt::numeric - avg_total_receipt::numeric, 2) AS difference
-- FROM smth2 CROSS JOIN smth3
-- WHERE avg_receipt > avg_total_receipt
-- ORDER BY difference DESC;


-- 12. Для каждой категории найди самый продаваемый товар (по количеству проданных единиц):
-- категория, товар, количество.
-- Подсказка: CTE с агрегацией по товарам, затем DISTINCT ON по категории.

-- WITH most_sold_products AS (
-- 	SELECT p.product_id, p.product_name, p.category_id,
-- 		SUM(od.quantity) AS quantity
-- 	FROM order_details AS od
-- 		JOIN products AS p ON od.product_id = p.product_id
-- 	GROUP BY p.product_id, p.product_name, p.category_id
-- )

-- SELECT DISTINCT ON (c.category_id) c.category_id, c.category_name, msp.product_name, msp.quantity
-- FROM most_sold_products AS msp
-- 	JOIN categories AS c ON msp.category_id = c.category_id
-- ORDER BY c.category_id, msp.quantity DESC, msp.product_id;


-- 13. Пользователи, которые смотрели товары, но ни разу ничего не добавили в корзину:
-- user_id, количество просмотров. Топ-20 по просмотрам.
-- Подсказка: NOT EXISTS с коррелированным подзапросом по тому же user_id.

-- SELECT user_id, COUNT(*) AS views_count
-- FROM events AS e
-- WHERE NOT EXISTS (SELECT 1 FROM events AS e1 WHERE e1.event_type = 'add_to_cart' AND e.user_id = e1.user_id)
-- 	AND e.event_type = 'view_product'
-- GROUP BY user_id
-- ORDER BY views_count DESC
-- LIMIT 20;


-- 14. Сравнение каналов привлечения:
-- канал, количество пользователей, количество активных,
-- среднее число событий на активного пользователя и доля канала от всех пользователей в процентах.

WITH users_events AS (
	SELECT
		u.user_id,
		u.acquisition_channel,
		COUNT(e.event_id) AS events_count
	FROM users AS u
		LEFT JOIN events AS e on e.user_id = u.user_id
	GROUP BY u.user_id, u.acquisition_channel
)

SELECT
	COALESCE(acquisition_channel, 'unknown') AS acquisition_channel,
	COUNT(*) AS users_count,
	COUNT(*) FILTER (WHERE events_count > 0) AS active_users,
	ROUND(SUM(events_count)::numeric
      / NULLIF(COUNT(*) FILTER (WHERE events_count > 0), 0), 2) AS events_per_active_user,
	ROUND(COUNT(*)::numeric / (SELECT COUNT(*) FROM users)::numeric * 100, 2)  AS ratio_percentage
FROM users_events
GROUP BY COALESCE(acquisition_channel, 'unknown')
ORDER BY users_count DESC;





















