# Оконные функции

Агрегат сворачивает группу в одну строку. Оконная функция считает то же самое, но **оставляет все строки на месте**, добавляя результат колонкой.

```
функция(аргументы) OVER ( [PARTITION BY ...] [ORDER BY ...] [рамка] )
```

Наличие `OVER` и делает функцию оконной.

---

## PARTITION BY и ORDER BY внутри OVER

```sql
SELECT category_id, product_name, unit_price,
       AVG(unit_price) OVER (PARTITION BY category_id) AS avg_in_category,
       ROW_NUMBER()    OVER (PARTITION BY category_id ORDER BY unit_price DESC) AS rn
FROM products;
```

- `PARTITION BY` делит строки на независимые окна. Без него окно — вся выборка.
- `ORDER BY` внутри `OVER` задаёт порядок **внутри окна**. Он не имеет отношения к `ORDER BY` всего запроса.

---

## Где оконную функцию использовать нельзя

Окна вычисляются **после** `WHERE`, `GROUP BY` и `HAVING`, но **до** `SELECT`:

```
FROM → WHERE → GROUP BY → HAVING → окна → SELECT → DISTINCT → ORDER BY → LIMIT
```

Поэтому в `WHERE` и `HAVING` оконную функцию положить нельзя — на момент фильтрации её ещё нет. Фильтровать по её результату можно только снаружи:

```sql
WITH ranked AS (
    SELECT category_id, product_name, unit_price,
           ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY unit_price DESC) AS rn
    FROM products
)
SELECT * FROM ranked WHERE rn <= 3;
```

**`LIMIT 3` здесь не работает** — он отрежет три строки от всего результата, а не по три в каждой категории. Это главная ловушка темы.

---

## Ранжирование

| Функция | Поведение при равных значениях |
|---|---|
| `ROW_NUMBER()` | 1, 2, 3, 4 — всегда разные номера, при ничьей порядок произволен |
| `RANK()` | 1, 2, 2, 4 — одинаковый ранг, следующий номер с пропуском |
| `DENSE_RANK()` | 1, 2, 2, 3 — одинаковый ранг, без пропуска |

```sql
SELECT product_name, units_in_stock,
       ROW_NUMBER() OVER (ORDER BY units_in_stock DESC) AS rn,
       RANK()       OVER (ORDER BY units_in_stock DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY units_in_stock DESC) AS dense
FROM products;
```

Чтобы увидеть разницу, сортировать нужно по колонке с повторами. **Если добавить в `ORDER BY` уникальный тай-брейк, все три функции совпадут** — ничьих не останется, и сравнение потеряет смысл.

Отсюда компромисс: тай-брейк делает `ROW_NUMBER` детерминированным, но разрушает смысл `RANK`. В задаче на сравнение тай-брейк не нужен; в задаче «взять топ-N» — нужен.

### Ранги и NULL

```sql
ROW_NUMBER() OVER (ORDER BY revenue DESC)
```

В `DESC` по умолчанию `NULLS FIRST`, поэтому после `LEFT JOIN` клиенты без выручки окажутся на первых местах. Лечится `ORDER BY revenue DESC NULLS LAST` или фильтром.

---

## NTILE

```sql
NTILE(4) OVER (ORDER BY revenue DESC)
```

Делит упорядоченные строки на N групп примерно равного **размера** и проставляет номер группы от 1 до N. Не по значению, а по количеству строк: `NTILE(4)` — квартили, `NTILE(10)` — децили.

Если строки не делятся нацело, первые группы получают на одну строку больше: 10 строк на 4 группы → 3, 3, 2, 2.

Важно: границы групп зависят только от позиции в сортировке. Две строки с одинаковым значением могут попасть в разные группы.

---

## Агрегаты в окне

Любой агрегат работает как оконная функция.

```sql
SELECT product_name, category_id, unit_price,
       AVG(unit_price) OVER (PARTITION BY category_id) AS avg_cat,
       unit_price - AVG(unit_price) OVER (PARTITION BY category_id) AS diff,
       SUM(revenue)    OVER (PARTITION BY category_id) AS category_revenue
FROM ...;
```

Это и есть главное преимущество окон: значение по группе оказывается рядом с каждой строкой без джойна на подзапрос.

### Доля от общего

```sql
100.0 * revenue / SUM(revenue) OVER (PARTITION BY category_id) AS share_pct
```

---

## Рамка окна

```
ROWS | RANGE  BETWEEN начало AND конец
```

Границы: `UNBOUNDED PRECEDING`, `N PRECEDING`, `CURRENT ROW`, `N FOLLOWING`, `UNBOUNDED FOLLOWING`.

### Умолчание, которое все забывают

- **Без `ORDER BY`** внутри `OVER` рамка — всё окно целиком: `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`.
- **С `ORDER BY`** рамка по умолчанию — `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

Поэтому добавление `ORDER BY` в `OVER` молча превращает агрегат по всему окну в **нарастающий итог**:

```sql
SUM(revenue) OVER (PARTITION BY category_id)                     -- итог по категории
SUM(revenue) OVER (PARTITION BY category_id ORDER BY month)      -- нарастающий итог
```

Это не ошибка синтаксиса, а смена смысла. Самая частая причина «почему числа не сходятся».

### ROWS против RANGE

`ROWS` считает физические строки. `RANGE` работает со значениями `ORDER BY`: все строки с одинаковым значением входят в рамку вместе. При уникальной сортировке разницы нет, при повторах — есть. Для скользящих средних почти всегда нужен `ROWS`.

### Нарастающий итог и скользящее среднее

```sql
-- нарастающий итог
SUM(revenue) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

-- скользящее среднее за 3 месяца
AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)

-- центрированное среднее
AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
```

У первых строк рамка короче: в первом месяце среднее считается по одной строке, во втором — по двум. Это нормально, но при сравнении с фактом начало ряда ведёт себя иначе.

---

## LAG и LEAD

```sql
LAG(выражение [, смещение [, значение_по_умолчанию]]) OVER (...)
LEAD(...)
```

- первый аргумент — что взять;
- второй — на сколько строк назад/вперёд, по умолчанию 1;
- третий — чем заменить, когда строки нет (первая строка для `LAG`, последняя для `LEAD`); по умолчанию `NULL`.

```sql
SELECT month, revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 1) AS growth_pct
FROM monthly;
```

Третий аргумент удобен, но опасен: `LAG(revenue, 1, 0)` подставит ноль в первый месяц, и прирост посчитается как деление на ноль или как 100% роста. Для первого периода честнее `NULL` и отдельная метка «нет данных».

Интервал между событиями клиента:

```sql
order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS days_since_prev
```

---

## FIRST_VALUE и LAST_VALUE

```sql
FIRST_VALUE(product_name) OVER (PARTITION BY category_id ORDER BY revenue DESC)
LAST_VALUE(product_name)  OVER (PARTITION BY category_id ORDER BY revenue DESC
                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
```

`LAST_VALUE` **почти всегда требует явной рамки**. По умолчанию рамка кончается на текущей строке, поэтому «последнее значение» совпадает с текущим — функция возвращает бесполезный результат, не выдавая ошибки.

---

## Именованное окно

Если одно и то же окно используется несколько раз:

```sql
SELECT product_name,
       ROW_NUMBER() OVER w AS rn,
       RANK()       OVER w AS rnk,
       DENSE_RANK() OVER w AS dense
FROM products
WINDOW w AS (PARTITION BY category_id ORDER BY unit_price DESC)
ORDER BY category_id, rn;
```

`WINDOW` ставится после `HAVING` и перед `ORDER BY`.

---

## Окно против GROUP BY

Если в результате нужна **одна строка на группу** — это `GROUP BY`. Окно здесь лишнее: придётся добавлять `DISTINCT`, чтобы убрать дубли, и запрос станет и медленнее, и непонятнее.

Окно нужно, когда рядом с **каждой** строкой должна стоять характеристика её группы, или когда считается что-то, зависящее от соседних строк.

---

## Чек-лист ошибок

| Симптом | Причина |
|---|---|
| `window functions are not allowed in WHERE` | Фильтр по окну — нужен CTE или внешний запрос |
| В каждой группе не по N строк | `LIMIT N` вместо `WHERE rn <= N` |
| Агрегат по окну превратился в нарастающий итог | Добавлен `ORDER BY` в `OVER` без явной рамки |
| `RANK` и `ROW_NUMBER` дали одно и то же | В `ORDER BY` добавлен уникальный тай-брейк |
| `LAST_VALUE` возвращает текущую строку | Не указана рамка `UNBOUNDED FOLLOWING` |
| В топе строки с `NULL` | `DESC` по умолчанию ставит `NULLS FIRST` |
| Дубли строк в результате | Окно там, где нужен `GROUP BY` |
| Прирост первого месяца равен 100% | Третий аргумент `LAG(x, 1, 0)` вместо `NULL` |
