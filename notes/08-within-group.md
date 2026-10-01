# WITHIN GROUP: упорядоченные агрегаты

## Зачем нужен WITHIN GROUP

Обычному агрегату безразличен порядок строк: `SUM`, `COUNT`, `AVG` дадут один ответ при любой перестановке. Но медиана, квартиль и мода без порядка не определены — чтобы взять «значение посередине», строки сначала надо выстроить в ряд.

Для таких функций есть отдельный синтаксис — **упорядоченные агрегаты** (ordered-set aggregates):

```
имя_функции(аргумент) WITHIN GROUP (ORDER BY выражение)
```

Аргумент в первых скобках — параметр функции (какой перцентиль нужен), `ORDER BY` в `WITHIN GROUP` — то, по чему сортируются данные внутри группы.

Этот `ORDER BY` **не влияет на сортировку результата**. Он задаёт только порядок, в котором функция видит значения. Сортировка выдачи — отдельный `ORDER BY` в конце запроса.

---

## PERCENTILE_CONT

```sql
PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY unit_price)   -- медиана
PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY unit_price)   -- первый квартиль
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY unit_price)   -- третий квартиль
PERCENTILE_CONT(0.9)  WITHIN GROUP (ORDER BY unit_price)   -- 90-й перцентиль
```

Аргумент — доля от 0 до 1. Вне диапазона — ошибка; `NULL` в аргументе даёт `NULL` в результате.

### Как вычисляется позиция

```
позиция = доля × (N − 1)        нумерация с нуля
```

Если позиция дробная, функция **интерполирует** между соседними значениями — результата может не быть в таблице.

| N | Позиция медианы | Результат |
|---|---|---|
| 77 (нечётное) | 0.5 × 76 = 38 | целая позиция → 39-й элемент, реальное значение |
| 10 (чётное) | 0.5 × 9 = 4.5 | дробная → среднее 5-го и 6-го |

Нумерация с нуля: позиция 38 означает, что до неё 38 элементов, а сама она 39-я по счёту. Поэтому при 77 строках слева и справа от медианы ровно по 38 значений.

---

## PERCENTILE_DISC

```sql
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY unit_price)
```

`DISC` — discrete. Возвращает **реально существующее** значение: первое, у которого накопленная доля достигает заданной. Ничего не усредняет.

| | `PERCENTILE_CONT` | `PERCENTILE_DISC` |
|---|---|---|
| Результат | может отсутствовать в данных | всегда из данных |
| Типы | только числа и интервалы | любой сортируемый тип, включая текст и даты |
| Когда брать | метрики, суммы, время — стандартный выбор | когда нужен конкретный существующий объект |

---

## MODE

```sql
SELECT
    MODE() WITHIN GROUP (ORDER BY acquisition_channel) AS top_channel,
    MODE() WITHIN GROUP (ORDER BY device)  AS top_device,
    MODE() WITHIN GROUP (ORDER BY country) AS top_country
FROM users;
```

Скобки пустые — аргумента нет. Работает с любым сравнимым типом, несколько мод считаются за один проход.

Три особенности:

| Особенность | Следствие |
|---|---|
| `NULL` игнорируются | `NULL` никогда не станет модой. Нужна замена заранее: `ORDER BY COALESCE(channel, 'unknown')` |
| Ничья решается сортировкой | При равной частоте побеждает первое по `ORDER BY` — то есть алфавит, а не данные |
| Не показывает долю | Победитель с 90% и с 22% выглядят одинаково |

Если нужна доля — `MODE` не подходит: берут `GROUP BY` + `COUNT` с `ORDER BY ... DESC LIMIT 1` или `ROW_NUMBER` в CTE.

---

## STRING_AGG и ARRAY_AGG

Это **обычные** агрегаты, не упорядоченные. Но порядок им важен, поэтому `ORDER BY` пишется прямо внутри скобок функции — без `WITHIN GROUP`:

```sql
STRING_AGG(product_name, ', ' ORDER BY unit_price DESC)
ARRAY_AGG(product_name ORDER BY unit_price DESC)
```

У `STRING_AGG` второй аргумент — разделитель, он обязателен. Перед `ORDER BY` запятая не ставится.

### Топ-N внутри группы

Ограничить список тремя элементами прямо в `STRING_AGG` нельзя — функция собирает всё, что ей дали. Отбор делается заранее, через `ROW_NUMBER` в CTE:

```sql
WITH ranked_products AS (
    SELECT product_name, category_id, unit_price,
           ROW_NUMBER() OVER (PARTITION BY category_id
                              ORDER BY unit_price DESC, product_id) AS rn
    FROM products
)
SELECT c.category_name,
       STRING_AGG(r.product_name, ', ' ORDER BY r.unit_price DESC) AS top_products
FROM categories AS c
    JOIN ranked_products AS r ON r.category_id = c.category_id
WHERE r.rn <= 3
GROUP BY c.category_id, c.category_name
ORDER BY c.category_id;
```

Почему фильтр снаружи: внутри CTE `rn` — оконная функция, в `WHERE` того же уровня она недоступна. Снаружи это уже обычная колонка.

**Две сортировки должны совпадать.** `ORDER BY` в `ROW_NUMBER` решает, *кого* отобрать; `ORDER BY` в `STRING_AGG` — *в каком порядке* перечислить. Рассогласовать их легко: получится «три самых дорогих, перечисленных по алфавиту».

---

## Гипотетические агрегаты

Отвечают на вопрос «какое место занял бы элемент со значением x, если бы его добавили в группу»:

```sql
SELECT RANK(50) WITHIN GROUP (ORDER BY unit_price DESC) FROM products;
```

Так же работают `DENSE_RANK`, `PERCENT_RANK`, `CUME_DIST`.

**Не путать с оконной `RANK()`** — это разные функции с одним именем, различаются тем, что идёт следом:

- `RANK() OVER (ORDER BY ...)` — оконная, без аргументов, даёт ранг каждой строке;
- `RANK(x) WITHIN GROUP (ORDER BY ...)` — агрегат, принимает значение, даёт одно число на группу.

---

## Главное ограничение: нельзя использовать как окно

У упорядоченных агрегатов нет формы с `OVER`. Запись

```sql
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) OVER (PARTITION BY category_id)
```

— синтаксическая ошибка.

Чтобы поставить медиану группы рядом с каждой строкой, её считают в CTE и подджойнивают:

```sql
WITH category_medians AS (
    SELECT category_id,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY unit_price) AS median_price
    FROM products
    GROUP BY category_id
),
with_deviation AS (
    SELECT p.product_name, p.unit_price, m.median_price,
           (p.unit_price - m.median_price) / NULLIF(m.median_price, 0) * 100 AS deviation_pct
    FROM products AS p
        JOIN category_medians AS m ON m.category_id = p.category_id
)
SELECT * FROM with_deviation
WHERE deviation_pct > 50
ORDER BY deviation_pct DESC;
```

Второй CTE не лишний: `WHERE` выполняется раньше `SELECT`, поэтому алиас `deviation_pct` в нём недоступен — без обёртки формулу пришлось бы написать дважды.

---

## Двухуровневая агрегация

Самая частая конструкция темы: метрика считается на одном уровне, перцентиль — на другом.

```sql
WITH order_totals AS (                     -- уровень 1: сумма каждого заказа
    SELECT order_id,
           SUM(unit_price * quantity * (1 - discount)) AS order_total
    FROM order_details
    GROUP BY order_id
),
quartiles AS (                             -- уровень 2: перцентили поверх сумм
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY order_total) AS q1,
        PERCENTILE_CONT(0.5)  WITHIN GROUP (ORDER BY order_total) AS median,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY order_total) AS q3
    FROM order_totals
)
SELECT ROUND(median::numeric, 2) AS median,
       ROUND(q1::numeric, 2) AS q1,
       ROUND(q3::numeric, 2) AS q3,
       ROUND(q3::numeric - q1::numeric, 2) AS iqr
FROM quartiles;
```

Третий уровень нужен по той же причине: алиас нельзя использовать в том же `SELECT`, где он объявлен.

---

## Что эти числа означают

### Медиана против среднего

Среднее тянут выбросы, медиану — нет. Если среднее заметно выше медианы, распределение перекошено вправо: несколько крупных значений тянут среднее вверх, а типичный объект скромнее.

На `products`: медиана 19.5, среднее ≈ 28.9. Половина каталога дешевле 19.5, а среднее задрано товарами вроде Côte de Blaye за 263.5. **Разница между средним и медианой — мера перекоса.**

### IQR

```
IQR = Q3 − Q1
```

Между Q1 и Q3 лежит «средняя половина» наблюдений, IQR — её ширина. В отличие от `MAX − MIN`, один гигантский заказ на IQR не влияет.

Отсюда стандартное правило поиска выбросов — то, что рисует «усы» у boxplot:

```
выброс, если  value < Q1 − 1.5 × IQR  или  value > Q3 + 1.5 × IQR
```

### Знаменатель рядом с метрикой

Агрегаты молча игнорируют `NULL`. Медиана времени доставки считается только по отправленным заказам: если половина месяца зависла, метрика покажет отличный результат по оставшимся. Поэтому рядом с метрикой ставят размер выборки:

```sql
COUNT(*)              AS total,       -- все строки группы
COUNT(delivery_days)  AS delivered    -- только непустые
```

### Порог значимости среза

Медиана по стране с двумя заказами — просто среднее двух чисел. Любая агрегатная метрика по срезу требует минимального размера выборки:

```sql
GROUP BY country
HAVING COUNT(*) >= 10
```

---

## Чек-лист ошибок

| Симптом | Причина |
|---|---|
| Порядок строк «плавает» | Нет `ORDER BY` в финальном запросе |
| В выборку попали отклонения вниз | `ABS` там, где в условии есть направление |
| Битые данные выглядят нормальными | `COALESCE(деление, 0)` вместо честного `NULL` |
| Лишний слой в запросе | CTE, за которым идёт просто `SELECT *` |
| Топ-N меняется между запусками | `ROW_NUMBER` без уникального поля в `ORDER BY` |
| Список отсортирован не так, как отобран | Разные `ORDER BY` в `ROW_NUMBER` и `STRING_AGG` |
| `NULL` не стал модой | `MODE` игнорирует `NULL` — нужен `COALESCE` до агрегата |

---

## Шпаргалка

| Задача | Функция |
|---|---|
| Типичное значение, устойчивое к выбросам | `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY x)` |
| Разброс середины | `PERCENTILE_CONT(0.75) − PERCENTILE_CONT(0.25)` |
| Существующее значение на границе | `PERCENTILE_DISC(p) WITHIN GROUP (ORDER BY x)` |
| Самое частое значение | `MODE() WITHIN GROUP (ORDER BY x)` |
| Список значений одной строкой | `STRING_AGG(x, ', ' ORDER BY y)` |
| Место гипотетического значения | `RANK(v) WITHIN GROUP (ORDER BY x)` |
| Медиана группы рядом с каждой строкой | CTE с `GROUP BY` + `JOIN` — окна не работают |
