-- 1. По всей таблице products: средняя цена, медиана, минимум
--    и максимум. Сравни среднюю с медианой и объясни разницу
--    в комментарии.

--SELECT
--	ROUND(AVG(unit_price)::numeric, 2) AS avg_price,
--	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY unit_price) AS median_price,
--	MAX(unit_price) AS max_price,
--	MIN(unit_price) AS min_price
--FROM products;

-- средняя цена на много больше потому что есть продукты с большими unit_price
-- медиана берёт по середине


-- 2. По категориям: название, количество товаров, средняя цена,
--    медианная цена и разница между ними. Отсортируй по разнице
--    по убыванию — сверху окажутся категории с самым сильным
--    перекосом.

--WITH categories_products AS (
--	SELECT c.category_id, c.category_name,
--		COUNT(*) AS products_count,
--		AVG(p.unit_price) AS avg_price,
--		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.unit_price) AS median_price
--	FROM products AS p
--		JOIN categories AS c ON p.category_id = c.category_id
--	GROUP BY c.category_id, c.category_name
--)
--
--SELECT category_name, products_count,
--	ROUND(avg_price::numeric, 2) AS avg_price,
--	ROUND(median_price::numeric, 2) AS median_price,
--	ROUND(avg_price::numeric - median_price::numeric, 2) AS difference
--FROM categories_products
--ORDER BY difference DESC, category_id;


-- 3. Медиана, первый и третий квартиль стоимости заказа
--    (по order_details). Плюс межквартильный размах — разница
--    между третьим и первым квартилем.

--WITH order_totals AS (
--	SELECT order_id,
--		SUM(unit_price * quantity * (1 - discount)) AS price
--	FROM order_details
--	GROUP BY order_id
--),
--quartiles AS (
--	SELECT
--		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median,
--		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS quartile_1,
--		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS quartile_3
--	FROM order_totals
--)
--
--SELECT
--	ROUND(median::numeric, 2) AS median,
--	ROUND(quartile_1::numeric, 2) AS quartile_1,
--	ROUND(quartile_3::numeric, 2) AS quartile_3,
--	ROUND(quartile_3::numeric - quartile_1::numeric, 2) AS iqr
--FROM quartiles;


-- 4. По странам клиентов: медиана суммы заказа и количество
--    заказов. Только страны минимум с 10 заказами, сортировка
--    по медиане по убыванию.

--WITH country_revenue AS (
--	SELECT c.country, o.order_id,
--		SUM(od.unit_price * od.quantity * (1 - od.discount)) AS order_price
--	FROM customers AS c
--		JOIN orders AS o ON o.customer_id = c.customer_id
--		JOIN order_details AS od ON od.order_id = o.order_id
--	GROUP BY c.country, o.order_id
--)
--
--SELECT country,
--	ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY order_price))::numeric, 2) AS median_price,
--	COUNT(*) AS orders_count
--FROM country_revenue
--GROUP BY country
--HAVING COUNT(*) >= 10
--ORDER BY median_price DESC;


-- 5. Медианное время доставки (shipped_date - order_date)
--    по месяцам 1997 года. Подсказка: разность дат даёт integer,
--    PERCENTILE_CONT его примет.

--WITH orders_delivery AS (
--	SELECT order_id, order_date, shipped_date,
--		shipped_date - order_date AS delivery_days
--	FROM orders
--	WHERE order_date >= '1997-01-01' AND order_date < '1998-01-01'
--)
--
--
--SELECT DATE_TRUNC('month', order_date)::date AS month,
--	COUNT(*) AS orders_total,
--	COUNT(delivery_days) AS delivered,
--	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delivery_days) AS delivery_days_median
--FROM orders_delivery
--GROUP BY 1
--ORDER BY month;


-- 6. Самый частый канал привлечения, самое частое устройство
--    и самая частая страна в users — три колонки в одной строке
--    через MODE.

--SELECT
--	MODE() WITHIN GROUP (ORDER BY acquisition_channel) AS most_common_acquisition_channel,
--	MODE() WITHIN GROUP (ORDER BY device) AS most_common_device,
--	MODE() WITHIN GROUP (ORDER BY country) AS most_common_country
--FROM users;


-- 7. Для каждого товара: название, цена, медианная цена его
--    категории и отклонение в процентах. Только товары, которые
--    дороже медианы своей категории больше чем на 50%.
--    Подсказка: WITHIN GROUP нельзя использовать как окно,
--    нужен CTE с джойном.

--WITH categories_median_price AS (
--	SELECT category_id,
--		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY unit_price) AS category_median_price
--	FROM products
--	GROUP BY category_id
--),
--products_category_median_price AS (
--	SELECT p.product_name, p.unit_price, cmp.category_median_price,
--		(p.unit_price - cmp.category_median_price) / NULLIF(cmp.category_median_price, 0) * 100 AS deviation_percentage
--	FROM products AS p
--		JOIN categories_median_price AS cmp ON p.category_id = cmp.category_id
--)
--
--SELECT product_name, unit_price,
--	ROUND(category_median_price::numeric, 2) AS category_median_price,
--	ROUND(deviation_percentage::numeric, 2) AS deviation_percentage
--FROM products_category_median_price
--WHERE deviation_percentage > 50
--ORDER BY deviation_percentage DESC, product_name;


-- 8. По категориям: название и список трёх самых дорогих товаров
--    одной строкой через запятую. Подсказка: STRING_AGG
--    с сортировкой внутри, а ограничение тремя товарами придётся
--    сделать заранее — через ROW_NUMBER в CTE.

--WITH ranked_products AS (
--	SELECT product_id, product_name, category_id, unit_price,
--		ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY unit_price DESC) AS rn
--	FROM products
--)
--
--SELECT c.category_id, c.category_name,
--	STRING_AGG(p.product_name, ', ' ORDER BY p.unit_price DESC) AS products
--FROM categories AS c
--	JOIN ranked_products AS p ON c.category_id = p.category_id
--WHERE rn <= 3
--GROUP BY c.category_id, c.category_name
--ORDER BY c.category_id;




