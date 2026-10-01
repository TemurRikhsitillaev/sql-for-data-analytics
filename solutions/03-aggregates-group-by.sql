-- 1. Посчитай количество товаров, среднюю, минимальную и максимальную цену по всей таблице products. 
-- Среднюю округли до 2 знаков.
-- SELECT COUNT(*) as total_products, 
-- 	ROUND(AVG(unit_price)::numeric, 2) as average_price,
-- 	MIN(unit_price) as min_price,
-- 	MAX(unit_price) as max_price
-- FROM products;

-- 2. Посчитай в orders: всего заказов, сколько из них отправлено, сколько не отправлено. 
-- Второе и третье получи из COUNT, без отдельных запросов.
-- SELECT COUNT(*) AS total_orders,
-- 	COUNT(shipped_date) AS shipped,
-- 	COUNT(*) - COUNT(shipped_date) AS not_shipped
-- FROM orders;

-- 3. Посчитай, сколько всего пользователей в users и сколько из них с известным каналом привлечения. 
-- Сколько с неизвестным?
-- SELECT COUNT(*) AS total_users,
-- 	COUNT(acquisition_channel) AS with_acquisition_channel,
-- 	COUNT(*) - COUNT(acquisition_channel) AS without_acquisition_channel
-- FROM users;

-- 4. Посчитай в events: всего событий, сколько разных пользователей и сколько разных сессий.
-- SELECT COUNT(*) AS total_events,
-- 	COUNT(DISTINCT user_id) AS unique_users,
-- 	COUNT(DISTINCT session_id) AS unique_sessions
-- FROM events;

-- 5. Количество товаров в каждой категории, от большего к меньшему.
-- SELECT category_id, COUNT(*) as total_products
-- FROM products
-- GROUP BY category_id
-- ORDER BY total_products DESC;

-- 6. Количество клиентов по странам, по алфавиту.
-- SELECT country, COUNT(*) AS total_clients
-- FROM customers
-- GROUP BY country
-- ORDER BY country;

-- 7. Для каждой категории: количество товаров, средняя цена (округли), самый дорогой товар по цене (MAX).
-- SELECT category_id, 
-- 	COUNT(*) AS total_products, 
-- 	ROUND(AVG(unit_price)::numeric, 2) AS avg_price,
-- 	MAX(unit_price) AS max_price
-- FROM products
-- GROUP BY category_id;

-- 8. Количество событий каждого типа в events, от частых к редким.
-- SELECT event_type, 
-- 	COUNT(*) AS total_events
-- FROM events
-- GROUP BY event_type
-- ORDER BY total_events DESC;

-- 9. Количество регистраций по каналам привлечения. 
-- Проверь, попала ли в результат группа с NULL, и объясни почему.
-- SELECT acquisition_channel,
-- 	COUNT(*) as total_registrations
-- FROM users
-- GROUP BY acquisition_channel;

-- 10. Посчитай количество событий по дням: выведи event_time::date под алиасом day и количество событий за этот день. 
-- Отсортируй по дате по возрастанию, покажи первые 7 дней.
-- SELECT event_time::date AS day, 
-- 	COUNT(*) as total_events
-- FROM events
-- GROUP BY event_time::date
-- ORDER BY day
-- LIMIT 7;

-- 11. Количество пользователей по паре «страна + устройство», отсортируй по стране, внутри по количеству по убыванию.
-- SELECT country, device, COUNT(*) as total_users
-- FROM users
-- GROUP BY country, device
-- ORDER BY country, total_users DESC;

-- 12. Посчитай количество заказов по паре «страна доставки + год заказа». 
-- Год бери как EXTRACT(YEAR FROM order_date) — эта функция вытаскивает часть даты, подробно разберём её позже. 
-- Отсортируй по стране, внутри по году.
-- SELECT ship_country, EXTRACT(YEAR FROM order_date) AS order_year, COUNT(*) AS total_orders
-- FROM orders
-- GROUP BY ship_country, EXTRACT(YEAR FROM order_date)
-- ORDER BY ship_country, order_year;

-- 13. Страны, в которых больше 5 клиентов.
-- SELECT country, COUNT(*) AS total_clients
-- FROM customers
-- GROUP BY country
-- HAVING COUNT(*) > 5;

-- 14. Категории, где средняя цена товара выше 30 и при этом товаров не меньше 5.
-- SELECT category_id, ROUND(AVG(unit_price)::numeric, 2) AS avg_price, COUNT(*) AS total_products
-- FROM products
-- GROUP BY category_id
-- HAVING AVG(unit_price) > 30 AND COUNT(*) >= 5;

-- 15. Пользователи (user_id) из events, у которых больше 10 событий, топ-20 по количеству.
-- SELECT user_id, COUNT(*) as total_events
-- FROM events
-- GROUP BY user_id
-- HAVING COUNT(*) > 10
-- ORDER BY total_events DESC
-- LIMIT 20;

-- 16. Сессии, в которых было больше 5 событий: session_id и количество, топ-10.
-- SELECT session_id, COUNT(*) AS total_events
-- FROM events
-- GROUP BY session_id
-- HAVING COUNT(*) > 5
-- ORDER BY total_events DESC, session_id
-- LIMIT 10;

-- 17. По order_details посчитай для каждого заказа итоговую сумму (unit_price * quantity * (1 - discount), округли)
-- и количество позиций. Оставь только заказы дороже 5000, топ-10 по сумме.
-- SELECT order_id, 
-- 	ROUND(SUM(unit_price::numeric * quantity * (1 - discount)::numeric), 2) AS total_price,
-- 	COUNT(*) AS items_count
-- FROM order_details
-- GROUP BY order_id
-- HAVING SUM(unit_price * quantity * (1 - discount)) > 5000
-- ORDER BY total_price DESC
-- LIMIT 10;

-- 18. По order_details посчитай для каждого товара, 
-- сколько всего единиц продано и в скольких разных заказах он встречался. 
-- Топ-10 по проданным единицам.
-- SELECT product_id, SUM(quantity) AS sold_quantity, COUNT(DISTINCT order_id) AS unique_orders_number
-- FROM order_details
-- GROUP BY product_id
-- ORDER BY sold_quantity DESC
-- LIMIT 10;

-- 19. По events посчитай для каждого товара количество просмотров (view_product) и
-- выведи топ-10. Обрати внимание, что фильтр по типу события идёт в WHERE, а не в HAVING.
-- SELECT product_id, COUNT(*) AS total_views
-- FROM events
-- WHERE event_type = 'view_product'
-- GROUP BY product_id
-- ORDER BY total_views DESC
-- LIMIT 10;

-- 20. По orders за 1997 год посчитай для каждого клиента количество заказов и 
-- среднее время доставки в днях (shipped_date - order_date). Оставь клиентов, 
-- у которых было минимум 5 заказов, отсортируй по среднему времени доставки по убыванию. 
-- Подумай, что происходит с неотправленными заказами при подсчёте среднего.
-- SELECT customer_id,
--        COUNT(*)              AS total_orders,     -- все заказы клиента
--        COUNT(shipped_date)   AS shipped_orders,   -- по скольким считалось среднее
--        AVG(shipped_date - order_date) AS avg_delivery_day
-- FROM orders
-- WHERE order_date >= '1997-01-01' AND order_date < '1998-01-01'
-- GROUP BY customer_id
-- HAVING COUNT(*) >= 5
-- ORDER BY avg_delivery_day DESC NULLS LAST;














