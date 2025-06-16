-- Этап 1. Создание и заполнение БД
/* Созадаем схему raw_data*/
create schema if not exists raw_data;


/* Создаем в схеме raw_data таблицу sales, в которую скопируем все данные из csv-файла */
create table raw_data.sales (
    id integer,
    auto varchar,
    gasoline_consumption real,
    price numeric(7, 2),
    date date,
    person varchar,
    phone varchar,
    discount integer,
    brand_origin varchar
);


/* Копирование таблицы. Командe вводиk в терминале psql
\copy raw_data.sales from 'E:\basic_SQL_project\cars.csv' with csv header NULL 'null';


/* Создаём схему car_shop, в которой будем создавать все таблицы */
create schema if not exists car_shop;


/* Создаем одну из родительских таблиц car_shop.client, в которую войдут данные по клиентам: имя, фамилия, особые отметки (научная степень), способ связи */
create table car_shop.client (
    customer_id SERIAL primary key,   -- первичный ключ с автоинкрементом
    first_name varchar not null,      -- в имени используются буквы и т.к. слова небольшой длины, то тип varchar, и здесь не должно быть пропускаов
    last_name varchar not null,       -- в фамилии используются буквы и т.к. слова небольшой длины, то тип varchar, и здесь не должно быть пропускаов
    special_marks varchar,            -- используются буквы и т.к. слова небольшой длины, то тип varchar. Здесь может быть много пропусков.
    phone varchar                     -- используются различные символы, поэтому тип varchar.
);


/* Создаем в схеме car_shop родительскую таблицу auto, содержащую данные по автомобилям: марка, модель, расход, страна происхождения бренда */
create table car_shop.auto (
    auto_id SERIAL primary key,       -- первичный ключ с автоинкрементом
    brand varchar not null,           -- в бренде используются буквы и т.к. слово небольшой длины, то тип varchar. Без пропусков
    model varchar not null,           -- в наименовании модели используются буквы и цифры и т.к. слова небольшой длины, то тип varchar. Без пропусков
    brand_origin varchar,             -- страна проихождения бренда используются буквы, слова небольшой длины, поэтому тип varchar. Могут быть пропуски.
    gasoline_consumption real          -- небольшие числовые дробные значения, поэтому тип real. Могу быть пропуски. 
);


/* Проверим какие есть приписки к именам в колонке person таблицы sales */
select person
from raw_data.sales
where cardinality (STRING_TO_ARRAY(person, ' ')) > 2;


/* Заполняем таблицу client, используя данные из таблицы sales схемы raw_data */
insert into car_shop.client (
    customer_id,
    first_name,
    last_name,
    special_marks,
    phone
) select
    id,
    -- Т.к. в person есть приписки (Dr., Miss и др), то формируем условия для нахождения имени клиента.
    case 
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 2 then split_part(person, ' ', 1)
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 3
    	     AND split_part(person, ' ', 1) in ('Dr.', 'Mrs.', 'Miss', 'Mr.') then split_part(person, ' ', 2)
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 3
    	     AND split_part(person, ' ', 1) not in ('Dr.', 'Mrs.', 'Miss', 'Mr.') then split_part(person, ' ', 1)
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 4 then split_part(person, ' ', 2)
    end,
    -- аналогично поступаем для поиска фамилии клиента
    case 
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 2 then split_part(person, ' ', 2)
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 3
    	     AND split_part(person, ' ', 1) in ('Dr.', 'Mrs.', 'Miss', 'Mr.') then split_part(person, ' ', 3)
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 3
    	     AND split_part(person, ' ', 1) not in ('Dr.', 'Mrs.', 'Miss', 'Mr.')
    	     and split_part(person, ' ', 3) not in ('Jr.', 'II') then split_part(person, ' ', 3)
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 3
    	     AND split_part(person, ' ', 1) not in ('Dr.', 'Mrs.', 'Miss', 'Mr.')
    	     and split_part(person, ' ', 3) in ('Jr.', 'II') then (split_part(person, ' ', 2) || ' ' || split_part(person, ' ', 3))   	     
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 4
    	     and split_part(person, ' ', 4) in ('Jr.', 'II') then (split_part(person, ' ', 3) || ' ' || split_part(person, ' ', 4))
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 4
    	     and split_part(person, ' ', 4) not in ('Jr.', 'II') then split_part(person, ' ', 3)    
    end,
    -- Теперь формируем колонку самих приписок
    case 
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 3
    	     AND split_part(person, ' ', 1) in ('Dr.', 'Mrs.', 'Miss', 'Mr.') then split_part(person, ' ', 1)
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 3
    	     AND split_part(person, ' ', 1) not in ('Dr.', 'Mrs.', 'Miss', 'Mr.')
    	     and split_part(person, ' ', 3) not in ('Jr.', 'II') then split_part(person, ' ', 3)
    	when cardinality (STRING_TO_ARRAY(person, ' ')) = 4
    	     and split_part(person, ' ', 4) not in ('Jr.', 'II') then (split_part(person, ' ', 1) || ' ' || split_part(person, ' ', 4))
    end,
    phone
from raw_data.sales;


/* Заполняем таблицу auto, используя данные из таблицы sales схемы raw_data */
insert into car_shop.auto (
    auto_id,
    brand,
    model,
    brand_origin,
    gasoline_consumption
) select
    id,
    split_part(auto, ' ', 1),
    LTRIM(split_part(auto, ',', 1), split_part(auto, ' ', 1)),
    brand_origin,
    gasoline_consumption
from raw_data.sales;


/* Создадим в схеме car_shop дочернюю таблицу invoice с колонками: id, auto_id (ссылка на таблицу auto), customer_id (ссылка на таблицу client),
 *                                                                 date, price, discount и цвет машины (car_color). */
create table car_shop.invoice (
     invoice_id SERIAL primary key,                                           -- первичный ключ с автоинкрементом
     customer_id integer references car_shop.client (customer_id),            -- внешний ключ, ссылается на customer_id в таблице client. Тип integer 
     auto_id integer references car_shop.auto (auto_id),                      -- внешний ключ, ссылается на auto_id в таблице auto. Тип integer 
     car_color varchar not null,                                              -- цвет автомобиля, содержит буквы, слова небольшие, поэтому тип varchar
     date date not null default current_date,                                 -- дата покупки, неможет быть пустой, тип date. Добавил по умолчанию текущую дату
     price numeric(7, 2) constraint invoice_price_positive check(price > 0),  -- цена в $ с учетом скидки, неможет быть отрицательной, по условию значащих цифр 7, после запятой достаточно 2-х. Поэтому numeric
     discount integer                                                         -- Скидка в %, тип integer
);


/* Заполняем таблицу car_shop.invoice */
insert into car_shop.invoice (
     invoice_id,
     customer_id,
     auto_id,
     car_color,
     date,
     price,
     discount
) select
     id,
     id,
     id,
     split_part(auto, ' ', -1),
     date,
     price,
     discount
from raw_data.sales;


-- Этап 2. Создание выборок

/* Задание 1 из 6. Напишите запрос, который выведет процент моделей машин, у которых нет параметра gasoline_consumption */
select (COUNT(auto_id) - COUNT(gasoline_consumption))::real *100 / COUNT(auto_id)
from car_shop.auto;


/* Задание 2 из 6. Напишите запрос, который покажет название бренда и среднюю цену его автомобилей в разбивке по всем годам с учётом скидки.
 * Итоговый результат отсортируйте по названию бренда и году в восходящем порядке. Среднюю цену округлите до второго знака после запятой. */
select
    brand,
    EXTRACT(YEAR FROM date) AS year,
    ROUND(AVG(price), 2) as price_avg
from car_shop.auto
join car_shop.invoice using (auto_id)
group by brand, year
order by brand;


/* Задание 3 из 6. Посчитайте среднюю цену всех автомобилей с разбивкой по месяцам в 2022 году с учётом скидки.
 * Результат отсортируйте по месяцам в восходящем порядке. Среднюю цену округлите до второго знака после запятой. */
select
    EXTRACT(MONTH FROM date) AS month,
    EXTRACT(YEAR FROM date) AS year,
    ROUND(AVG(price), 2) as price_avg
from car_shop.auto
join car_shop.invoice using (auto_id)
group by month, year 
having EXTRACT(YEAR FROM date) = '2022'
order by month;


/* Задание 4 из 6. Используя функцию STRING_AGG, напишите запрос, который выведет список купленных машин у каждого пользователя через запятую.
 * Пользователь может купить две одинаковые машины — это нормально. Название машины покажите полное, с названием бренда — например: Tesla Model 3.
 * Отсортируйте по имени пользователя в восходящем порядке. Сортировка внутри самой строки с машинами не нужна. */
select
    (first_name || ' ' || last_name) as person,
    STRING_AGG((brand || ' ' || model), ', ') as cars
from car_shop.auto
join car_shop.invoice using (auto_id)
join car_shop.client using (customer_id)
group by person
order by person;


/* Задание 5 из 6. Напишите запрос, который вернёт самую большую и самую маленькую цену продажи автомобиля с разбивкой по стране без учёта скидки.
 * Цена в колонке price дана с учётом скидки. */
select
    brand_origin,
    ROUND((MAX((price * 100) / (100 - discount))), 2) as price_max,    
    ROUND((MIN((price * 100) / (100 - discount))), 2) as price_min
from car_shop.auto
join car_shop.invoice using (auto_id)
group by brand_origin
having brand_origin is not null;


/* Задание 6 из 6. Напишите запрос, который покажет количество всех пользователей из США. Это пользователи, у которых номер телефона начинается на +1. */
select COUNT(customer_id) as persons_from_usa_count
from car_shop.client
where phone like '+1%';




