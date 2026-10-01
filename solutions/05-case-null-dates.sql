-- 1. Ценовые сегменты по категориям.
-- Для каждой категории посчитай, сколько в ней товаров каждого ценового сегмента
-- (до 10 — budget, 10–50 — medium, дороже 50 — premium),
-- тремя отдельными колонками в одной строке.
-- Плюс общее количество товаров и средняя цена (округли до 2 знаков).
-- Снятые с продажи не учитывай. Сортировка по общему количеству по убыванию.

--SELECT c.category_id, c.category_name,
--	COUNT(p.product_id) FILTER (WHERE p.unit_price < 10) AS budget,
--	COUNT(p.product_id) FILTER (WHERE p.unit_price BETWEEN 10 AND 50) AS medium,
--	COUNT(p.product_id) FILTER (WHERE p.unit_price > 50) AS premium,
--	COUNT(p.product_id) AS total_products,
--	ROUND(AVG(p.unit_price)::numeric, 2) AS avg_price
--FROM categories AS c
--	JOIN products AS p ON c.category_id = p.category_id
--WHERE p.discontinued = 0
--GROUP BY c.category_id, c.category_name
--ORDER BY total_products DESC;


-- 2. Статусы заказов по странам.
-- Для каждой страны доставки посчитай всего заказов, из них неотправленных,
-- опоздавших (shipped_date > required_date) и вовремя — четырьмя колонками.
-- Добавь колонку late_share: доля опоздавших в процентах от общего числа, округли до 1 знака.
-- Оставь страны минимум с 10 заказами, сортировка по late_share по убыванию.

--SELECT ship_country,
--	COUNT(*) AS total_orders_count,
--	COUNT(*) FILTER (WHERE shipped_date IS NULL) AS not_shipped_orders_count,
--	COUNT(*) FILTER (WHERE shipped_date > required_date) AS late_orders_count,
--	COUNT(*) FILTER (WHERE shipped_date <= required_date) AS on_time_orders_count,
--	ROUND(COUNT(*) FILTER (WHERE shipped_date > required_date) * 100.0 / COUNT(*), 1) AS late_share
--FROM orders
--GROUP BY ship_country
--HAVING COUNT(*) >= 10
--ORDER BY late_share DESC;

-- 3. Воронка по товарам.
-- Для каждого товара из events:
-- название, количество просмотров, количество добавлений в корзину,
-- конверсия в процентах (округли до 1 знака) и
-- оценка (high выше 30%, normal 15–30%, low ниже).
-- Товары с нулём просмотров не должны ломать запрос.
-- Оставь товары минимум с 50 просмотрами, топ-10 по конверсии.

-- 3. Воронка по товарам.
-- Для каждого товара из events:
-- название, количество просмотров, количество добавлений в корзину,
-- конверсия в процентах (округли до 1 знака) и
-- оценка (high выше 30%, normal 15–30%, low ниже).
-- Товары с нулём просмотров не должны ломать запрос.
-- Оставь товары минимум с 50 просмотрами, топ-10 по конверсии.

--SELECT products.product_name,
--	COUNT(*) FILTER (WHERE event_type = 'view_product') AS views_count,
--	COUNT(*) FILTER (WHERE event_type = 'add_to_cart') AS add_to_cart_count,
--	ROUND(COUNT(*) FILTER (WHERE event_type = 'add_to_cart')::numeric / NULLIF(COUNT(*) FILTER (WHERE event_type = 'view_product'), 0) * 100, 1) AS conversion,
--	CASE
--	  WHEN COUNT(*) FILTER (WHERE event_type = 'add_to_cart')
--	       > 0.3 * COUNT(*) FILTER (WHERE event_type = 'view_product') THEN 'high'
--	  WHEN COUNT(*) FILTER (WHERE event_type = 'add_to_cart')
--	       >= 0.15 * COUNT(*) FILTER (WHERE event_type = 'view_product') THEN 'normal'
--	  ELSE 'low'
--	END AS rating
--FROM events
--	JOIN products ON events.product_id = products.product_id
--WHERE event_type IN ('view_product', 'add_to_cart')
--GROUP BY events.product_id, products.product_name
--HAVING COUNT(*) FILTER (WHERE event_type = 'view_product') >= 50
--ORDER BY conversion DESC
--LIMIT 10;


-- 4. Динамика выручки по месяцам.
-- По заказам за всё время посчитай для каждого месяца:
-- месяц (первым числом, тип date), выручку (округли), количество заказов,
-- количество разных клиентов и среднюю сумму заказа.
-- Сортировка по месяцу.
-- Подумай, откуда брать количество заказов, чтобы позиции заказа его не раздули.

--SELECT DATE_TRUNC('month', o.order_date)::date AS month,
--	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric), 2) AS revenue,
--	COUNT(DISTINCT o.order_id) AS orders_count,
--	COUNT(DISTINCT o.customer_id) AS customers_count,
--	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric) / NULLIF(COUNT(DISTINCT od.order_id), 0), 2) AS avg_order_price
--FROM orders AS o
--	JOIN order_details AS od ON o.order_id = od.order_id
--GROUP BY DATE_TRUNC('month', o.order_date)::date
--ORDER BY month;


-- 5. Сезонность против динамики.
-- Сделай два запроса и сравни результаты:
-- в первом выручка по номеру месяца (январь всех лет вместе, 12 строк),
-- во втором выручка по месяцам с годом (DATE_TRUNC).
-- Объясни в комментарии, какой вопрос решает каждый.

-- Этот запрос решает сколько покупок и т.д. в каждом месяце за всё время

-- SELECT EXTRACT(MONTH FROM o.order_date) AS month,
-- 	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric), 2) AS revenue,
-- 	COUNT(DISTINCT o.order_id) AS orders_count,
-- 	COUNT(DISTINCT o.customer_id) AS customers_count,
-- 	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric) / NULLIF(COUNT(DISTINCT od.order_id), 0), 2) AS avg_order_price
-- FROM orders AS o
-- 	JOIN order_details AS od ON o.order_id = od.order_id
-- GROUP BY EXTRACT(MONTH FROM o.order_date)
-- ORDER BY month;

-- Этот запрос решает сколько покупок и т.д. за каждых месяц каждого года

--SELECT DATE_TRUNC('month', o.order_date)::date AS month,
--	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric), 2) AS revenue,
--	COUNT(DISTINCT o.order_id) AS orders_count,
--	COUNT(DISTINCT o.customer_id) AS customers_count,
--	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric) / NULLIF(COUNT(DISTINCT od.order_id), 0), 2) AS avg_order_price
--FROM orders AS o
--	JOIN order_details AS od ON o.order_id = od.order_id
--GROUP BY DATE_TRUNC('month', o.order_date)::date
--ORDER BY month;


-- 6. Жизненный цикл клиента.
-- Для каждого клиента:
-- название компании, страна, дата первого заказа, дата последнего,
-- сколько дней между ними, количество заказов, суммарная выручка и
-- средний интервал между заказами в днях
-- (дни между первым и последним, делённые на число заказов минус один — защити от деления на ноль).
-- Только клиенты минимум с 5 заказами, топ-10 по выручке.

--SELECT c.company_name,
--	c.country,
--	MIN(o.order_date) AS first_order_date,
--	MAX(o.order_date) AS last_order_date,
--	COALESCE(MAX(o.order_date) - MIN(o.order_date), 0) AS days_between_last_first_orders,
--	COUNT(DISTINCT o.order_id) AS orders_count,
--	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric), 2) AS revenue,
--	ROUND((MAX(o.order_date) - MIN(o.order_date))::numeric
--      / NULLIF(COUNT(DISTINCT o.order_id) - 1, 0), 1) AS avg_interval_between_orders
--FROM customers AS c
--	LEFT JOIN orders AS o ON c.customer_id = o.customer_id
--	LEFT JOIN order_details AS od ON o.order_id = od.order_id
--GROUP BY c.customer_id, c.company_name, c.country
--HAVING COUNT(DISTINCT o.order_id) >= 5
--ORDER BY revenue DESC
--LIMIT 10;


-- 7. Отчёт по категориям за два года.
-- Для каждой категории в одной строке:
-- название, выручка за 1997, выручка за 1998,
-- прирост в процентах ((1998 − 1997) / 1997 × 100, округли до 1 знака, защити от нуля)
-- и оценка динамики (рост, если прирост больше 0, падение, если меньше, без изменений, если ровно 0).
-- Сортировка по приросту по убыванию.

--SELECT c.category_name,
--	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric) FILTER (WHERE o.order_date >= '1997-01-01' AND o.order_date < '1998-01-01'), 2) AS "revenue in 1997",
--	ROUND(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric) FILTER (WHERE o.order_date >= '1998-01-01' AND o.order_date < '1999-01-01'), 2) AS "revenue in 1998",
--	ROUND(
--		(
--			SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric) FILTER (WHERE o.order_date >= '1998-01-01' AND o.order_date < '1999-01-01')
--			-
--			SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric) FILTER (WHERE o.order_date >= '1997-01-01' AND o.order_date < '1998-01-01')
--		)
--		/
--		NULLIF(SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric) FILTER (WHERE o.order_date >= '1997-01-01' AND o.order_date < '1998-01-01'), 0)
--		*
--		100
--		, 1) AS "percentage increase",
--	CASE
--		WHEN
--			SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric) FILTER (WHERE o.order_date >= '1998-01-01' AND o.order_date < '1999-01-01')
--			>
--			SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric) FILTER (WHERE o.order_date >= '1997-01-01' AND o.order_date < '1998-01-01')
--		THEN 'прирост'
--		WHEN SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric) FILTER (WHERE o.order_date >= '1998-01-01' AND o.order_date < '1999-01-01')
--			<
--			SUM(od.unit_price::numeric * od.quantity * (1 - od.discount)::numeric) FILTER (WHERE o.order_date >= '1997-01-01' AND o.order_date < '1998-01-01')
--		THEN 'падение'
--		ELSE 'ровно'
--	END
--	AS "assessment of trends"
--FROM categories AS c
--	JOIN products AS p ON c.category_id = p.category_id
--	JOIN order_details AS od ON p.product_id = od.product_id
--	JOIN orders AS o ON o.order_id = od.order_id
--WHERE o.order_date >= '1997-01-01' AND o.order_date < '1999-01-01'
--GROUP BY c.category_id, c.category_name
--ORDER BY "percentage increase" DESC NULLS LAST;


-- 8. Портрет пользователя по каналам.
-- Для каждого канала привлечения (NULL замени на unknown):
-- количество пользователей, из них с iOS, с Android, с web (тремя колонками),
-- количество пользователей, у которых есть хотя бы одно событие, и
-- доля активных в процентах (округли до 1 знака).
-- Сортировка по количеству пользователей по убыванию.

--SELECT
--		COALESCE(u.acquisition_channel, 'unknown') AS channel,
--		COUNT(DISTINCT u.user_id) AS users,
--		COUNT(DISTINCT u.user_id) FILTER (WHERE u.device = 'ios') AS ios,
--		COUNT(DISTINCT u.user_id) FILTER (WHERE u.device = 'android') AS android,
--		COUNT(DISTINCT u.user_id) FILTER (WHERE u.device = 'web') AS web,
--		COUNT(DISTINCT u.user_id) FILTER (WHERE e.event_id IS NOT NULL) AS active_users,
--		ROUND(COUNT(DISTINCT u.user_id) FILTER (WHERE e.event_id IS NOT NULL)::numeric / COUNT(DISTINCT u.user_id) * 100, 1) AS active_share
--FROM users AS u
--	LEFT JOIN events AS e ON u.user_id = e.user_id
--GROUP BY COALESCE(u.acquisition_channel, 'unknown')
--ORDER BY users DESC;


-- 9. Активность по дням недели и времени суток.
-- По events: для каждого дня недели (EXTRACT(DOW ...),
-- выведи название дня через CASE: 0 — воскресенье и так далее) посчитай количество событий,
-- количество разных сессий и количество просмотров товаров.
-- Плюс колонка со средним количеством событий на сессию (округли до 2 знаков).
-- Сортировка по дню недели с понедельника.

--SELECT
--	CASE EXTRACT(ISODOW FROM event_time)
--		WHEN 7 THEN 'воскресенье'
--		WHEN 1 THEN 'понедельник'
--		WHEN 2 THEN 'вторник'
--		WHEN 3 THEN 'среда'
--		WHEN 4 THEN 'четверг'
--		WHEN 5 THEN 'пятница'
--		WHEN 6 THEN 'суббота'
--	END AS weekday,
--	COUNT(*) AS events_count,
--	COUNT(DISTINCT session_id) AS sessions_count,
--	COUNT(*) FILTER (WHERE event_type = 'view_product') AS view_products_count,
--	ROUND(COUNT(*)::numeric / NULLIF(COUNT(DISTINCT session_id), 0), 2) AS events_sessions_avg_count
--FROM events
--GROUP BY EXTRACT(ISODOW FROM event_time)
--ORDER BY EXTRACT(ISODOW FROM event_time);


-- 10. Проблемные товары.
-- Найди товары, которые либо закончились на складе, либо их нужно дозаказать.
-- Для каждого выведи: название, категорию,
-- остаток, заказано у поставщика,
-- уровень дозаказа,
-- статус (out_of_stock, если остаток 0, reorder_needed, если units_in_stock + units_on_order <= reorder_level,
-- ok иначе) и
-- сколько единиц продали за последние 90 дней от даты последнего заказа в базе.
-- Снятые с продажи не нужны.
-- Сортировка: сначала out_of_stock, потом reorder_needed, внутри по проданным единицам по убыванию.

-- Подсказка 10:
-- «последние 90 дней» проще всего получить как (SELECT MAX(order_date) FROM orders) - 90,
-- это подзапрос, который мы ещё не проходили.
-- Если не хочешь забегать вперёд, возьми фиксированную дату '1998-02-01' и считай от неё.
SELECT
	p.product_id,
	p.product_name,
	c.category_name,
	p.units_in_stock,
	p.units_on_order,
	p.reorder_level,
	CASE
		WHEN p.units_in_stock = 0 THEN 'out_of_stock'
		WHEN p.units_in_stock + p.units_on_order <= p.reorder_level THEN 'reorder_needed'
		ELSE 'ok'
	END AS status,
	COALESCE(SUM(od.quantity) FILTER (
    WHERE o.order_date >= '1998-02-01'::date - INTERVAL '90 days'
      AND o.order_date <  '1998-02-01'), 0) AS sold_past_90_days

FROM products AS p
 JOIN categories AS c ON p.category_id = c.category_id
 LEFT JOIN order_details od ON p.product_id = od.product_id
 LEFT JOIN orders AS o ON od.order_id = o.order_id

WHERE p.discontinued = 0

GROUP BY p.product_id, p.product_name, c.category_name, p.units_in_stock, p.units_on_order, p.reorder_level

ORDER BY p.units_in_stock = 0 DESC, p.units_in_stock + p.units_on_order <= p.reorder_level DESC, sold_past_90_days DESC;








































