-- 1. Товары с их порядковым номером по цене внутри категории:
-- категория, товар, цена, номер.
-- Сначала посмотри на результат целиком,
-- потом оставь только топ-3 в каждой категории.

-- WITH products_categories AS (
-- 	SELECT c.category_name, p.product_name, p.unit_price,
-- 	ROW_NUMBER() OVER (PARTITION BY p.category_id ORDER BY p.unit_price DESC, p.product_id) AS rn
-- 	FROM products AS p
-- 	JOIN categories AS c ON p.category_id = c.category_id
-- )

-- Без топ 3 по каждой категории

-- SELECT * FROM products_categories;

-- С топ 3 по каждой категории

-- SELECT *
-- FROM products_categories
-- WHERE rn <= 3
-- ORDER BY category_name, rn;


-- 2. Сравни ROW_NUMBER, RANK и DENSE_RANK на товарах,
--    отсортированных по units_in_stock (там много одинаковых
--    значений). Тремя колонками в одном запросе, объясни
--    разницу в комментарии.

--SELECT product_id, product_name, units_in_stock,
--	ROW_NUMBER() OVER w AS rn,
--	RANK() OVER w AS rnk,
--	DENSE_RANK() OVER w AS dense
--FROM products
--WINDOW w AS (ORDER BY units_in_stock DESC)
--ORDER BY units_in_stock DESC, product_id;

-- row_number  — всегда разные номера подряд: 1, 2, 3, 4
-- rank        — при равных значениях одинаковый ранг,
--               следующий перескакивает на количество ничьих: 1, 2, 2, 4
-- dense_rank  — при равных значениях одинаковый ранг,
--               следующий идёт подряд: 1, 2, 2, 3


-- 3. Топ-3 клиента по выручке в каждой стране: страна, клиент,
--    выручка, ранг.

--WITH customers_revenue AS (
--	SELECT c.country, c.company_name,
--		SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
--	FROM customers AS c
--		JOIN orders AS o ON c.customer_id = o.customer_id
--		JOIN order_details AS od ON od.order_id = o.order_id
--	GROUP BY c.country, c.company_name
--),
--ranked AS (
--	SELECT country, company_name, ROUND(revenue::numeric, 2) AS revenue,
--		RANK() OVER(PARTITION BY country ORDER BY revenue DESC) AS rnk
--	FROM customers_revenue
--)
--
--SELECT * FROM ranked
--WHERE rnk <= 3
--ORDER BY country, rnk;


-- 4. Раздели клиентов на 4 группы по выручке через NTILE(4):
--    клиент, выручка, номер квартиля. Затем посчитай, сколько
--    клиентов в каждом квартиле и какая в нём средняя выручка.

--WITH customers_revenue AS (
--	SELECT c.customer_id, c.company_name,
--		SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
--	FROM customers AS c
--		JOIN orders AS o ON c.customer_id = o.customer_id
--		JOIN order_details AS od ON od.order_id = o.order_id
--	GROUP BY c.customer_id, c.company_name
--),
--ntiled AS (
--	SELECT customer_id, company_name, revenue,
--		NTILE(4) OVER (ORDER BY revenue DESC) AS quartile
--	FROM customers_revenue
--)
--
--SELECT company_name, ROUND(revenue::numeric, 2) AS revenue, quartile,
--	COUNT(*) OVER w AS customers_count,
--	ROUND((AVG(revenue) OVER w)::numeric, 2) AS avg_revenue,
--	ROUND((MAX(revenue) OVER w)::numeric, 2) AS max_revenue,
--	ROUND((MIN(revenue) OVER w)::numeric, 2) AS min_revenue
--FROM ntiled
--WINDOW w AS (PARTITION BY quartile)
--ORDER BY quartile, revenue DESC;


-- 5. Товары с ценой, средней ценой по категории и разницей
--    между ними. Отсортируй по разнице по убыванию.

--SELECT product_name, unit_price,
--	ROUND((AVG(unit_price) OVER w)::numeric, 2) AS avg_unit_price_by_category,
--	ROUND(unit_price::numeric - (AVG(unit_price) OVER w)::numeric, 2) AS difference
--FROM products
--WINDOW w AS (PARTITION BY category_id)
--ORDER BY difference DESC, product_id;


-- 6. Доля каждого товара в выручке своей категории: товар,
--    категория, выручка товара, выручка категории, доля
--    в процентах.

--WITH products_revenue AS (
--	SELECT p.product_id, p.product_name, p.category_id, c.category_name,
--		SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
--	FROM products AS p
--		JOIN order_details AS od ON p.product_id = od.product_id
--		JOIN categories AS c ON c.category_id = p.category_id
--	GROUP BY p.product_id, p.product_name, p.category_id, c.category_name
--),
--products_category_revenue AS (
--	SELECT product_name, category_name, revenue,
--		SUM(revenue) OVER (PARTITION BY category_id) AS category_revenue
--	FROM products_revenue
--)
--
--SELECT product_name, category_name,
--	ROUND(revenue::numeric, 2) as revenue,
--	ROUND(category_revenue::numeric, 2) AS category_revenue,
--	ROUND(revenue::numeric / category_revenue::numeric * 100, 2) AS share_percentage
--FROM products_category_revenue
--ORDER BY category_name, share_percentage DESC;


-- 7. Нарастающий итог выручки по месяцам 1997 года: месяц,
--    выручка за месяц, нарастающий итог, доля накопленного
--    от годового итога.

--WITH month_revenue AS (
--    SELECT EXTRACT(MONTH FROM o.order_date) AS month,
--           SUM(od.unit_price::numeric * od.quantity * (1 - od.discount::numeric)) AS revenue
--    FROM orders AS o
--    JOIN order_details AS od ON od.order_id = o.order_id
--    WHERE o.order_date >= '1997-01-01' AND o.order_date < '1998-01-01'
--    GROUP BY EXTRACT(MONTH FROM o.order_date)
--)
--SELECT month,
--       ROUND(revenue, 2) AS revenue,
--       ROUND(SUM(revenue) OVER w, 2) AS cumulative_revenue,
--       ROUND(SUM(revenue) OVER w / SUM(revenue) OVER () * 100, 2) AS cumulative_share
--FROM month_revenue
--WINDOW w AS (ORDER BY month)
--ORDER BY month;


-- 8. Выручка по месяцам с приростом к предыдущему месяцу
--    в процентах. Добавь колонку с оценкой: рост, падение,
--    нет данных (для первого месяца).

--WITH orders_revenue AS (
--	SELECT
--		DATE_TRUNC('month', o.order_date)::date AS month,
--		SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
--	FROM orders AS o
--		JOIN order_details AS od ON od.order_id = o.order_id
--	GROUP BY 1
--),
--orders_prev_month_revenue AS (
--	SELECT month, revenue,
--		(LAG(revenue) OVER (ORDER BY month)) AS prev_month_revenue
--	FROM orders_revenue
--)
--
--SELECT month,
--	ROUND(revenue::numeric, 2) AS revenue,
--	ROUND(prev_month_revenue::numeric, 2) AS prev_month_revenue,
--	ROUND((revenue - prev_month_revenue)::numeric / prev_month_revenue::numeric * 100, 2) AS growth_percentage,
--	CASE
--		WHEN prev_month_revenue IS NULL THEN 'нет данных'
--		WHEN revenue > prev_month_revenue THEN 'рост'
--		WHEN revenue < prev_month_revenue THEN 'падение'
--		ELSE 'ровно'
--	END
--	AS rating
--FROM orders_prev_month_revenue
--ORDER BY month;


-- 9. Для каждого клиента: дата заказа, дата предыдущего заказа
--    и сколько дней прошло между ними. Только клиенты минимум
--    с 5 заказами.

--WITH customers_orders AS (
--	SELECT customer_id, order_date,
--		LAG(order_date) OVER w AS prev_order_date,
--		COUNT(*) OVER (PARTITION BY customer_id) AS orders_count
--	FROM orders
--	WINDOW w AS (PARTITION BY customer_id ORDER BY order_date)
--)
--
--SELECT customer_id, order_date, prev_order_date,
--	order_date - prev_order_date AS days_difference
--FROM customers_orders
--WHERE orders_count >= 5
--ORDER BY customer_id, order_date;


-- 10. Скользящее среднее выручки по месяцам за 3 месяца.
--     Выведи месяц, выручку и сглаженное значение,
--     сравни колонки.

--WITH months_revenue AS (
--	SELECT DATE_TRUNC('month', o.order_date)::date AS month,
--		SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
--	FROM order_details AS od
--		JOIN orders AS o ON o.order_id = od.order_id
--	GROUP BY 1
--)
--
--SELECT month, ROUND(revenue::numeric, 2) AS revenue,
--	ROUND((AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW))::numeric, 2) AS avg_past_3_months_revenue
--FROM months_revenue
--ORDER BY month;


-- 11. Для каждой категории: товар с максимальной выручкой
--     и товар с минимальной, в одной строке. Подсказка:
--     FIRST_VALUE и LAST_VALUE с явной рамкой, потом DISTINCT.

--WITH products_revenue AS (
--	SELECT p.product_id, p.product_name, c.category_id, c.category_name,
--		SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
--	FROM order_details AS od
--		JOIN products AS p ON od.product_id = p.product_id
--		JOIN categories AS c ON p.category_id = c.category_id
--	GROUP BY p.product_id, p.product_name, c.category_id, c.category_name
--)
--
--
--SELECT DISTINCT category_name,
--	FIRST_VALUE(product_name) OVER (PARTITION BY category_id ORDER BY revenue DESC) AS max_revenue_product,
--	LAST_VALUE(product_name) OVER (PARTITION BY category_id ORDER BY revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS min_revenue_product
--FROM products_revenue
--ORDER BY category_name;


-- 12. Найди «аномальные» месяцы: те, где выручка отличается
--     от скользящего среднего за 3 месяца больше чем на 30%.
--     Выведи месяц, выручку, среднее и отклонение в процентах.

--WITH revenues_by_month AS (
--	SELECT DATE_TRUNC('month', o.order_date)::date AS month,
--		SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
--	FROM order_details AS od
--		JOIN orders AS o ON od.order_id = o.order_id
--	GROUP BY 1
--),
--avg_past_3_months AS (
--	SELECT month,
--		ROUND(revenue::numeric, 1) AS revenue,
--		ROUND((AVG(revenue) OVER w)::numeric, 1) AS avg_past_3_months_revenue,
--		ROUND(revenue::numeric / (AVG(revenue) OVER w)::numeric * 100 - 100, 1) AS difference
--	FROM revenues_by_month
--	WINDOW w AS (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
--)
--
--SELECT * FROM avg_past_3_months WHERE ABS(difference) >= 30;


-- 13. Воронка по сессиям: для каждой сессии определи, была ли
--     последовательность view_product -> add_to_cart. Выведи
--     session_id, количество событий, было ли добавление
--     в корзину, и время от первого события сессии
--     до добавления.

--SELECT session_id,
--	COUNT(*) AS events_count,
--	(COUNT(*) FILTER (WHERE event_type = 'add_to_cart')) > 0 AS is_added_to_cart,
--	MIN(event_time) AS session_start,
--	MIN(event_time) FILTER (WHERE event_type = 'add_to_cart') AS session_add_to_cart,
--	ROUND(EXTRACT(EPOCH FROM (MIN(event_time) FILTER (WHERE event_type = 'add_to_cart') - MIN(event_time)))::numeric / 60, 2) AS minutes_to_cart
--FROM events
--GROUP BY session_id
--ORDER BY session_id;


-- 14. Для каждого пользователя найди его первое и последнее
--     событие и посчитай длительность «жизни» в днях. Топ-20
--     по длительности среди пользователей минимум
--     с 10 событиями.

--SELECT user_id,
--	COUNT(*) AS events_count,
--	MIN(event_time) AS first_event,
--	MAX(event_time) AS last_event,
--	MAX(event_time)::date - MIN(event_time)::date AS lifetime_days
--FROM events
--GROUP BY user_id
--HAVING COUNT(*) >= 10
--ORDER BY lifetime_days DESC, user_id
--LIMIT 20;