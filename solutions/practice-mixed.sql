-- 1. Опоздавшие заказы.
-- Найди заказы, отправленные позже требуемой даты (required_date). 
-- Выведи order_id, customer_id, required_date, shipped_date и количество дней опоздания под алиасом days_late. 
-- Отсортируй от самых сильно опоздавших, при равенстве по order_id. Покажи только топ-10.
-- SELECT order_id, customer_id, required_date, shipped_date, shipped_date - required_date AS days_late
-- FROM orders
-- WHERE shipped_date > required_date
-- ORDER BY days_late DESC, order_id
-- LIMIT 10;

-- 2. Что пора дозаказать.
-- Найди товары, которые ещё продаются и у которых остаток на складе вместе с уже заказанным (units_on_order) не превышает уровень дозаказа (reorder_level). 
-- Товары с reorder_level = 0 не учитывай. 
-- Выведи название, остаток, заказано, уровень дозаказа и сколько не хватает до уровня под алиасом shortage. 
-- Сортировка: сначала самые дефицитные.
-- SELECT 
-- 	product_name, 
-- 	units_in_stock, 
-- 	units_on_order, 
-- 	reorder_level, 
-- 	reorder_level - (units_in_stock + units_on_order) AS shortage
-- FROM products
-- WHERE discontinued = 0 AND ((units_in_stock + units_on_order) <= reorder_level) AND reorder_level <> 0
-- ORDER BY shortage DESC;

-- 3. Щедрые скидки.
-- Из order_details найди строки заказов со скидкой 20% и больше, у которых сумма после скидки больше 1000. 
-- Выведи order_id, product_id, сумму до скидки (gross), сумму после скидки (net) и размер скидки в деньгах (saved). 
-- Все суммы округли до 2 знаков. 
-- Сортировка по saved по убыванию.
-- SELECT order_id, product_id,
-- 	ROUND(unit_price::numeric * quantity, 2) AS gross,
-- 	ROUND(unit_price::numeric * quantity * (1 - discount::numeric), 2) AS net,
-- 	ROUND(unit_price::numeric * quantity * discount::numeric, 2) AS saved
-- FROM order_details
-- WHERE discount >= 0.20 AND (unit_price * quantity * (1 - discount::numeric)) > 1000
-- ORDER BY saved DESC;

-- 4. Контакты-менеджеры.
-- Найди клиентов, у которых должность контактного лица (contact_title) содержит слово manager в любом регистре,
-- но не содержит sales. 
-- Дополнительно: у клиента не указан факс. 
-- Выведи company_name, country и одной колонкой "Контакт" в формате Maria Anders (Sales Representative). 
-- Отсортируй по стране, внутри по названию компании.
-- SELECT company_name, country, contact_name || ' (' || contact_title || ')' AS "Контакт"
-- FROM customers
-- WHERE 
-- 	(contact_title ILIKE '%manager%') AND
-- 	NOT(contact_title ILIKE '%sales%') AND
-- 	fax IS NULL
-- ORDER BY country, company_name;

-- 5. Главный заказ клиента в 1997 году.
-- Для каждого клиента найди его заказ 1997 года с самой высокой стоимостью доставки (freight). 
-- Если у двух заказов одинаковый freight, бери более ранний. 
-- Выведи customer_id, order_id, order_date, freight.
-- SELECT DISTINCT ON (customer_id) customer_id, order_id, order_date, freight
-- FROM orders
-- WHERE order_date BETWEEN '1997-01-01' AND '1997-12-31'
-- ORDER BY customer_id, freight DESC, order_date, order_id;

-- 6. Выборка пользователей для рассылки.
-- Из users отбери пользователей с iOS или Android из Германии, Франции или UK,
-- зарегистрированных в четвёртом квартале 2025 года. 
-- Канал привлечения не должен быть paid_search, но пользователи с неизвестным каналом должны попасть в выборку.
-- Отсортируй по дате регистрации (при равенстве по user_id) и выведи вторую страницу по 10 человек.
-- SELECT user_id, device, country, registered_at, acquisition_channel
-- FROM users
-- WHERE 
-- 	device IN ('ios', 'android') AND 
-- 	country IN ('Germany', 'France', 'UK') AND
-- 	registered_at >= '2025-10-01' AND
-- 	registered_at < '2026-01-01' AND
-- 	(acquisition_channel <> 'paid_search' OR acquisition_channel IS NULL)
-- ORDER BY registered_at, user_id
-- LIMIT 10
-- OFFSET 10;

-- 7. Ранние покупатели.
-- Найди события добавления в корзину, которые произошли с 07:00 до 07:29 включительно,
-- за любой месяц 2025 года, где есть данные. 
-- Выведи user_id, product_id, event_time и отдельной колонкой только время события под алиасом event_clock. 
-- Сортировка по времени суток, от самого раннего, при равенстве по event_time.
-- SELECT user_id, product_id, event_time, event_time::time AS event_clock
-- FROM events
-- WHERE event_type = 'add_to_cart' AND
-- 	event_time::time >= '07:00:00' AND
-- 	event_time::time < '07:30' AND
-- 	event_time::date BETWEEN '2025-01-01' AND '2025-12-31' AND
-- 	product_id IS NOT NULL
-- ORDER BY event_clock;

-- 8. Неполные контакты.
-- Найди клиентов не из USA, у которых не заполнено ровно одно из двух полей: fax или region. 
-- Если не заполнены оба или заполнены оба, клиент не подходит. 
-- Выведи company_name, country, region, fax. 
-- Подсказка: подумай, как записать «ровно одно из двух» через AND и OR (и не забудь про скобки).
-- SELECT company_name, country, region, fax
-- FROM customers
-- WHERE country <> 'USA' AND
-- 	((fax IS NULL AND region IS NOT NULL) OR (fax IS NOT NULL AND region IS NULL));

-- 9. Короткие названия.
-- Найди товары, название которых состоит ровно из одного слова (без пробелов) 
-- и начинается на букву от A до G включительно. 
-- Товары, снятые с продажи, не нужны. 
-- Выведи название и цену, по алфавиту. 
-- Решить нужно без функций, только операторами сравнения и LIKE.
-- SELECT product_name, unit_price
-- FROM products
-- WHERE product_name NOT LIKE '% %' AND
-- 	product_name >= 'A' AND product_name < 'H' AND
-- 	discontinued = 0
-- ORDER BY product_name;

-- 10. Проблемные заказы Q1 1998.
-- Найди заказы первого квартала 1998 года с доставкой не в USA,
-- которые либо ещё не отправлены, либо отправлены с опозданием (позже required_date). 
-- Выведи order_id, ship_country, order_date, required_date, shipped_date. 
-- Сначала должны идти неотправленные, потом опоздавшие. 
-- Внутри каждой группы сортировка по дате заказа.
-- SELECT order_id, ship_country, order_date, required_date, shipped_date
-- FROM orders
-- WHERE order_date BETWEEN '1998-01-01' AND '1998-03-31' AND
-- 	ship_country <> 'USA' AND
-- 	(shipped_date IS NULL OR shipped_date > required_date)
-- ORDER BY (shipped_date IS NULL) DESC, order_date








