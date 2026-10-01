# Подзапросы и CTE

## Скалярный подзапрос

Возвращает ровно одно значение и может стоять там же, где обычное выражение.

```sql
SELECT product_name, unit_price,
       unit_price - (SELECT AVG(unit_price) FROM products) AS diff_from_avg
FROM products
WHERE unit_price > (SELECT AVG(unit_price) FROM products);
```

Подзапрос выполняется один раз, его результат подставляется как константа. Если он вернёт больше одной строки — ошибка выполнения.

---

## Подзапрос в WHERE: IN

```sql
SELECT DISTINCT product_id
FROM order_details
WHERE order_id IN (
    SELECT order_id FROM orders
    WHERE customer_id IN (
        SELECT customer_id FROM customers WHERE country = 'Germany'
    )
);
```

Подзапрос возвращает список значений, внешний запрос проверяет вхождение.

### Ловушка NOT IN с NULL

```sql
WHERE customer_id NOT IN (SELECT customer_id FROM orders)
```

Если в подзапросе встретится хотя бы один `NULL`, **результат будет пустым**.

Причина в трёхзначной логике. `x NOT IN (a, b, NULL)` разворачивается в `x <> a AND x <> b AND x <> NULL`. Последнее сравнение всегда `NULL`, а `TRUE AND NULL` = `NULL`, и строка не проходит фильтр. Так происходит для каждой строки.

Запрос не падает — он просто возвращает ноль строк, и это выглядит как «таких клиентов нет».

Решения: `NOT EXISTS`, либо `WHERE col IS NOT NULL` внутри подзапроса.

---

## EXISTS и NOT EXISTS

```sql
SELECT company_name
FROM customers AS c
WHERE NOT EXISTS (
    SELECT 1 FROM orders AS o WHERE o.customer_id = c.customer_id
);
```

`EXISTS` проверяет сам факт наличия хотя бы одной строки и возвращает `TRUE`/`FALSE` — **никогда `NULL`**. Поэтому `NOT EXISTS` свободен от проблемы `NOT IN`.

Что стоит в `SELECT` подзапроса, неважно: `SELECT 1` — конвенция, показывающая, что значения не используются.

Это **коррелированный** подзапрос: он ссылается на `c.customer_id` из внешнего запроса и логически выполняется для каждой внешней строки. Планировщик обычно переписывает его в анти-джойн, так что медленнее это не делает.

```sql
-- пользователи, которые смотрели товары, но ничего не добавили в корзину
SELECT e.user_id, COUNT(*) AS views
FROM events AS e
WHERE e.event_type = 'view_product'
  AND NOT EXISTS (
      SELECT 1 FROM events AS a
      WHERE a.user_id = e.user_id AND a.event_type = 'add_to_cart'
  )
GROUP BY e.user_id
ORDER BY views DESC
LIMIT 20;
```

---

## Подзапрос в FROM (производная таблица)

Когда метрика считается на одном уровне, а статистика — поверх неё, нужна двухуровневая агрегация.

```sql
SELECT ROUND(AVG(order_total)::numeric, 2) AS avg_order,
       MIN(order_total) AS min_order,
       MAX(order_total) AS max_order
FROM (
    SELECT order_id, SUM(unit_price * quantity * (1 - discount)) AS order_total
    FROM order_details
    GROUP BY order_id
) AS t;
```

Нельзя написать `AVG(SUM(...))` — вложенные агрегаты запрещены. Подзапрос в `FROM` обязан иметь алиас.

---

## CTE (WITH)

То же самое, но читается сверху вниз.

```sql
WITH order_totals AS (
    SELECT order_id, SUM(unit_price * quantity * (1 - discount)) AS order_total
    FROM order_details
    GROUP BY order_id
)
SELECT ROUND(AVG(order_total)::numeric, 2) AS avg_order
FROM order_totals;
```

### Несколько CTE

Перечисляются через запятую, `WITH` пишется один раз. Каждый следующий может ссылаться на предыдущие.

```sql
WITH monthly AS (
    SELECT DATE_TRUNC('month', o.order_date)::date AS month,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
    FROM orders AS o
        JOIN order_details AS od ON od.order_id = o.order_id
    WHERE o.order_date >= '1997-01-01' AND o.order_date < '1998-01-01'
    GROUP BY 1
),
total AS (
    SELECT SUM(revenue) AS year_revenue FROM monthly
)
SELECT m.month,
       ROUND(m.revenue::numeric, 2) AS revenue,
       ROUND(100.0 * m.revenue / t.year_revenue, 1) AS share_pct
FROM monthly AS m
    CROSS JOIN total AS t
ORDER BY m.month;
```

`CROSS JOIN` с CTE из одной строки — стандартный приём, чтобы «раздать» общий итог каждой строке. Условие для соединения не нужно: одна строка умножается на каждую.

---

## Зачем CTE нужен: алиас в своём SELECT не виден

Это главная причина, по которой появляется второй уровень.

```sql
SELECT
    SUM(revenue) AS total,
    SUM(revenue) / 12 AS avg_month,
    total / 12                     -- ошибка: алиас total ещё не существует
FROM ...
```

Алиас становится доступен только в `ORDER BY`. Поэтому расчёт, опирающийся на уже посчитанное значение, выносят этажом выше:

```sql
WITH q AS (
    SELECT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY x) AS q1,
           PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY x) AS q3
    FROM t
)
SELECT q1, q3, q3 - q1 AS iqr FROM q;
```

То же касается `WHERE`: он выполняется раньше `SELECT`, поэтому фильтр по вычисленной колонке требует обёртки — иначе формулу придётся повторить целиком, и при правке легко исправить одну копию и забыть вторую.

### Когда CTE не нужен

```sql
WITH x AS (SELECT ... GROUP BY ...)
SELECT * FROM x;
```

Если внешний запрос — просто `SELECT *`, слой лишний. CTE оправдан, когда:

- меняется уровень агрегации;
- нужен алиас в `WHERE`;
- результат используется больше одного раза;
- запрос иначе нечитаем.

---

## DISTINCT ON в CTE

«Самый продаваемый товар в каждой категории» — сначала агрегат, потом выбор лучшего:

```sql
WITH product_sales AS (
    SELECT p.category_id, p.product_name, SUM(od.quantity) AS units_sold
    FROM products AS p
        JOIN order_details AS od ON od.product_id = p.product_id
    GROUP BY p.category_id, p.product_name
)
SELECT DISTINCT ON (category_id) category_id, product_name, units_sold
FROM product_sales
ORDER BY category_id, units_sold DESC, product_name;
```

`ORDER BY` обязан начинаться с выражения из `DISTINCT ON`; остальное решает, какая строка останется. Без него вернётся произвольная строка группы.

Та же задача решается через `ROW_NUMBER` — см. конспект по оконным функциям.

---

## Чек-лист ошибок

| Симптом | Причина |
|---|---|
| `NOT IN` вернул пусто | В подзапросе есть `NULL` — нужен `NOT EXISTS` |
| `more than one row returned by a subquery` | Скалярный подзапрос вернул больше строки |
| `subquery in FROM must have an alias` | Забыт алиас производной таблицы |
| `aggregate function calls cannot be nested` | `AVG(SUM(...))` — нужна двухуровневая агрегация |
| Алиас «не существует» | Используется в том же `SELECT` или в `WHERE` — нужен CTE |
| Результат меняется между запусками | `DISTINCT ON` без полного `ORDER BY` |
| Формула продублирована | Фильтр по вычисленному значению без обёртки в CTE |
