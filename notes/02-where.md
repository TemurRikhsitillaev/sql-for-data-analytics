# WHERE: фильтрация строк

`WHERE` выполняется сразу после `FROM` — раньше, чем `SELECT`. Отсюда главное следствие: **алиас из `SELECT` в `WHERE` использовать нельзя**.

```sql
SELECT product_name, unit_price * units_in_stock AS stock_value
FROM products
WHERE stock_value > 3000;          -- ошибка: column "stock_value" does not exist
```

Решения — повторить выражение или завернуть запрос в CTE:

```sql
WHERE unit_price * units_in_stock > 3000
```

---

## Операторы сравнения

| Оператор | Смысл |
|---|---|
| `=` | равно |
| `<>` или `!=` | не равно (`<>` — стандарт, `!=` — синоним) |
| `<`, `>`, `<=`, `>=` | сравнение |

«Не превышает» = `<=`, «не меньше» = `>=`. На формулировках вроде «остаток вместе с заказанным не превышает уровень дозаказа» легко промахнуться на одну границу — читать нужно буквально.

---

## AND, OR, NOT и приоритет

Приоритет: `NOT` → `AND` → `OR`. То есть `AND` связывает сильнее, чем `OR`, — как умножение сильнее сложения.

```sql
-- без скобок: category_id = 1 ИЛИ (category_id = 2 И unit_price < 20)
WHERE category_id = 1 OR category_id = 2 AND unit_price < 20

-- со скобками: (1 или 2) И дешевле 20
WHERE (category_id = 1 OR category_id = 2) AND unit_price < 20
```

Первый вариант вернёт **все** товары категории 1, включая дорогие. Запрос отработает, результат будет неверным. Ставь скобки всегда, когда в условии есть и `AND`, и `OR`.

---

## IN

```sql
SELECT customer_id, country FROM customers
WHERE country IN ('UK', 'France', 'Spain')
ORDER BY country;
```

`IN (...)` — сокращение для цепочки `OR`. `NOT IN (...)` — отрицание.

**`IN` сравнивает значение целиком.** `product_name IN ('A','B','C')` найдёт товар с названием ровно «A», а не все названия на букву A. Для диапазона букв используется сравнение строк: `product_name >= 'A' AND product_name < 'H'`.

**Ловушка `NOT IN` с `NULL`** разобрана в конспекте по подзапросам: если в списке встретится `NULL`, результат будет пустым.

---

## BETWEEN

```sql
WHERE unit_price BETWEEN 10 AND 20
```

Эквивалент `unit_price >= 10 AND unit_price <= 20`. Границы **включаются**.

### Почему BETWEEN опасен для дат

```sql
WHERE order_date BETWEEN '1997-12-01' AND '1997-12-31'
```

Если колонка имеет тип `date` — всё верно. Если `timestamp`, то `'1997-12-31'` раскрывается в `1997-12-31 00:00:00`, и **весь последний день теряется**: заказ в 14:30 не попадёт.

Надёжный способ — полуинтервал: включительно слева, исключительно справа.

```sql
WHERE order_date >= '1997-12-01' AND order_date < '1998-01-01'
```

Он работает одинаково для `date` и `timestamp`, не требует знать, сколько дней в месяце, и не ломается на високосных годах. Это рабочий стандарт для любых интервалов времени.

В Northwind `order_date` — `date`, а в аналитической таблице `events` поле `event_time` — `timestamp`. Проверить: `\d orders` в psql или `pg_typeof(order_date)`.

---

## LIKE и ILIKE

| Шаблон | Значение |
|---|---|
| `%` | любое количество символов, включая ноль |
| `_` | ровно один любой символ |

```sql
WHERE product_name ILIKE '%sauce%'   -- содержит
WHERE customer_id LIKE 'B%'          -- начинается с
WHERE last_name LIKE '%n'            -- заканчивается на
```

`LIKE` учитывает регистр, `ILIKE` — нет (расширение PostgreSQL). Для поиска по пользовательскому вводу почти всегда нужен `ILIKE`.

Отрицание: `NOT LIKE`, `NOT ILIKE`.

```sql
-- название из одного слова: нет ни одного пробела
WHERE product_name NOT LIKE '% %'
```

Частая ошибка: `LIKE '_'` означает «строка ровно из одного символа», а не «одно слово».

Комбинация условий на один столбец:

```sql
WHERE contact_title ILIKE '%manager%'
  AND contact_title NOT ILIKE '%sales%'
```

---

## NULL

`NULL` — не значение, а его отсутствие. Поэтому с ним не работают обычные сравнения:

```sql
WHERE region = NULL      -- всегда NULL → строка не попадает в результат, никогда
WHERE region IS NULL     -- правильно
WHERE region IS NOT NULL
```

Любая арифметика и сравнение с `NULL` дают `NULL`, а `WHERE` пропускает строку только при `TRUE`. Поэтому `= NULL` и `<> NULL` молча не находят ничего.

### Трёхзначная логика

У условия три исхода: `TRUE`, `FALSE`, `NULL` («неизвестно»).

```sql
WHERE acquisition_channel <> 'organic'
```

Этот фильтр **не вернёт** пользователей, у которых канал `NULL`: сравнение даст `NULL`, а не `TRUE`. Если такие строки нужны, их добавляют явно:

```sql
WHERE acquisition_channel <> 'organic' OR acquisition_channel IS NULL
```

Или одним оператором:

```sql
WHERE acquisition_channel IS DISTINCT FROM 'organic'
```

`IS DISTINCT FROM` сравнивает, считая `NULL` обычным значением: `NULL IS DISTINCT FROM 'organic'` → `TRUE`. Есть и обратный — `IS NOT DISTINCT FROM`.

---

## Чек-лист ошибок

| Симптом | Причина |
|---|---|
| `column ... does not exist` в `WHERE` | Использован алиас из `SELECT` |
| Отфильтровалось больше, чем ожидалось | `AND`/`OR` без скобок |
| Потерялся последний день периода | `BETWEEN` по `timestamp` — нужен полуинтервал `>= ... AND < ...` |
| Строки с `NULL` пропали | `<>` вместо `IS DISTINCT FROM` |
| `= NULL` ничего не находит | Нужен `IS NULL` |
| Поиск по подстроке не находит | `LIKE` вместо `ILIKE`, или забыты `%` |
| Фильтр «снятые с продажи» дал не то | `discontinued = 0` вместо `= 1` — ноль означает «продаётся» |
