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


/* Копирование таблицы. Команду вводил в терминале psql */
\copy raw_data.sales from 'E:\basic_SQL_project\cars.csv' with csv header NULL 'null';



-- Создаем схему car_shop и шесть таблиц в ней: countries, brands, models, colors, clients и invoice


/* Создаём схему car_shop, в которой будем создавать все таблицы */
create schema if not exists car_shop;


/* Создаем таблицу countries, в которой будут храниться страны происхождения бренда */
create table car_shop.countries(
    brand_origin_id SERIAL primary key,          -- первичный ключ с автоинкрементом
    brand_origin varchar not null UNIQUE         -- страна проихождения бренда используются буквы, слова небольшой длины, поэтому тип varchar. Страны уникальны
);


/* Создаем таблицу брендов - brands, в ней будут храниться наименования брендов и внешний ключ на страну происхождения бреднда countries.brand_origin_id */
create table car_shop.brands (
    brand_id SERIAL primary key,                                                 -- первичный ключ с автоинкрементом
    brand varchar not null UNIQUE,                                               -- в бренде используются буквы и т.к. слово небольшой длины, то тип varchar. Без пропусков. Бренды уникальны
    brand_origin_id integer references car_shop.countries (brand_origin_id)      -- внешний ключ, ссылается на brand_origin_id в таблице countries. Тип integer 
);


/* Создаем таблицу моделей models, в ней будут храниться наименования моделей, расход топлива и внешний ключ на бренд */
create table car_shop.models (
    model_id SERIAL primary key,                                 -- первичный ключ с автоинкрементом
    model varchar not null,                                      -- в наименовании модели используются буквы и цифры и т.к. слова небольшой длины, то тип varchar. Без пропусков
    brand_id integer references car_shop.brands (brand_id),      -- внешний ключ, ссылается на brand_id в таблице brands. Тип integer
    gasoline_consumption real                                    -- небольшие числовые дробные значения, поэтому тип real. Могу быть пропуски. 
);


/* Создаем таблицу colors, в которой будут храниться все цвета */
create table car_shop.colors (
    color_id SERIAL primary key,           -- первичный ключ с автоинкрементом
    color varchar not null UNIQUE          -- наименование цвета уникальны. Т.к. слова небольшие, то тип varchar. Без пропусков
);


/* Создаем таблицу clients, содержащию персональные данные клиентов */
create table car_shop.clients (
    customer_id SERIAL primary key,   -- первичный ключ с автоинкрементом
    first_name varchar not null,      -- в имени используются буквы и т.к. слова небольшой длины, то тип varchar, и здесь не должно быть пропускаов
    last_name varchar not null,       -- в фамилии используются буквы и т.к. слова небольшой длины, то тип varchar, и здесь не должно быть пропускаов
    special_marks varchar,            -- особые отметки (ученая степень и т.п.) используются буквы и т.к. слова небольшой длины, то тип varchar. Здесь может быть много пропусков.
    phone varchar                     -- используются различные символы, поэтому тип varchar.
);


/* Создаем таблицу invoice */
create table car_shop.invoice (
     invoice_id SERIAL primary key,                                            -- первичный ключ с автоинкрементом
     customer_id integer references car_shop.clients (customer_id),            -- внешний ключ, ссылается на customer_id в таблице client. Тип integer 
     model_id integer references car_shop.models (model_id),                   -- внешний ключ, ссылается на model_id в таблице models. Тип integer 
     color_id integer references car_shop.colors (color_id),                   -- внешний ключ, ссылается на color_id в таблице colors. Тип integer
     date date not null default current_date,                                  -- дата покупки, неможет быть пустой, тип date. Добавил по умолчанию текущую дату
     price numeric(7, 2) constraint invoice_price_positive check(price > 0),   -- цена в $ с учетом скидки, неможет быть отрицательной, по условию значащих цифр 7, после запятой достаточно 2-х. Поэтому numeric
     discount integer                                                          -- Скидка в %, тип integer
);


-- Переносим из таблицы raw_data.sales соответствующие данные в созданные таблицы countries, brands, models, colors, clients и invoice


/* Создадим в схеме raw_data вспомогательную таблицу с уникальными person */
create table raw_data.person (
    id SERIAL primary key,
    person varchar,
    phone varchar
);


/* Перенесем данные из таблицы sales в таблицу person */
insert into raw_data.person (
    id,
    person,
    phone
) select distinct on (person)
    id,
    person,
    phone
from raw_data.sales
;


/* Проверим какие есть приписки к именам в колонке person таблицы sales */
select person
from raw_data.sales
where cardinality (STRING_TO_ARRAY(person, ' ')) > 2;


/* Заполняем таблицу clients, используя данные из вспомогательной таблицы person схемы raw_data */
insert into car_shop.clients (
    first_name,
    last_name,
    special_marks,
    phone
) select
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
from raw_data.person;


/* Заполним таблицу car_shop.countries данными из таблицы raw_data.sales */
insert into car_shop.countries (
    brand_origin
) select distinct on (brand_origin)
    brand_origin    
from raw_data.sales
where sales.brand_origin is not null;


/* Заполним таблицу car_shop.colors данными из таблицы raw_data.sales */
insert into car_shop.colors (
    color
) select distinct on (split_part(auto, ' ', -1))
    split_part(auto, ' ', -1)    
from raw_data.sales;


/* Заполним таблицу car_shop.brands данными из таблицы raw_data.sales */
insert into car_shop.brands (
    brand,
    brand_origin_id
) select distinct on (split_part(auto, ' ', 1))
    split_part(auto, ' ', 1),
    brand_origin_id
from raw_data.sales
left join car_shop.countries using (brand_origin)
;


/* Заполним таблицу car_shop.models данными из таблицы raw_data.sales */
insert into car_shop.models (
    model,
    brand_id,
    gasoline_consumption
) select distinct on (TRIM(split_part(auto, ',', 1), split_part(auto, ' ', 1)))
    LTRIM(split_part(auto, ',', 1), split_part(auto, ' ', 1)),
    brand_id,
    gasoline_consumption
from raw_data.sales
join car_shop.countries using (brand_origin)
join car_shop.brands using (brand_origin_id)
;


/* Заполняем таблицу car_shop.invoice */
insert into car_shop.invoice (
     customer_id,            
     model_id,                   
     color_id,                   
     date,                                 
     price,
     discount
) select
     customer_id,
     model_id,
     color_id,
     date,
     price,
     discount
from raw_data.sales
join car_shop.clients using (phone)
join car_shop.models on (LTRIM(split_part(auto, ',', 1), split_part(auto, ' ', 1))) = model
join car_shop.colors on (split_part(auto, ' ', -1)) = color
;


-- Далее Этап 2. Создание выборок 


/* Задание 1 из 6. Напишите запрос, который выведет процент моделей машин, у которых нет параметра gasoline_consumption */
select (COUNT(model_id) - COUNT(gasoline_consumption))::real *100 / COUNT(model_id)
from car_shop.models;


/* Задание 2 из 6. Напишите запрос, который покажет название бренда и среднюю цену его автомобилей в разбивке по всем годам с учётом скидки.
 * Итоговый результат отсортируйте по названию бренда и году в восходящем порядке. Среднюю цену округлите до второго знака после запятой. */
select
    brand,
    EXTRACT(YEAR FROM date) AS year,
    ROUND(AVG(price), 2) as price_avg
from car_shop.invoice
join car_shop.models using (model_id)
join car_shop.brands using (brand_id)
group by brand, year
order by brand;


/* Задание 3 из 6. Посчитайте среднюю цену всех автомобилей с разбивкой по месяцам в 2022 году с учётом скидки.
 * Результат отсортируйте по месяцам в восходящем порядке. Среднюю цену округлите до второго знака после запятой. */
select
    EXTRACT(MONTH FROM date) AS month,
    EXTRACT(YEAR FROM date) AS year,
    ROUND(AVG(price), 2) as price_avg
from car_shop.invoice
group by month, year 
having EXTRACT(YEAR FROM date) = '2022'
order by month;


/* Задание 4 из 6. Используя функцию STRING_AGG, напишите запрос, который выведет список купленных машин у каждого пользователя через запятую.
 * Пользователь может купить две одинаковые машины — это нормально. Название машины покажите полное, с названием бренда — например: Tesla Model 3.
 * Отсортируйте по имени пользователя в восходящем порядке. Сортировка внутри самой строки с машинами не нужна. */
select
    (first_name || ' ' || last_name) as person,
    STRING_AGG((brand || ' ' || model), ', ') as cars
from car_shop.invoice
join car_shop.clients using (customer_id)
join car_shop.models using (model_id)
join car_shop.brands using (brand_id)
group by person
order by person;


/* Задание 5 из 6. Напишите запрос, который вернёт самую большую и самую маленькую цену продажи автомобиля с разбивкой по стране без учёта скидки.
 * Цена в колонке price дана с учётом скидки. */
select
    brand_origin,
    ROUND((MAX((price * 100) / (100 - discount))), 2) as price_max,    
    ROUND((MIN((price * 100) / (100 - discount))), 2) as price_min
from car_shop.invoice
join car_shop.models using (model_id)
join car_shop.brands using (brand_id)
join car_shop.countries using (brand_origin_id)
group by brand_origin
having brand_origin is not null;


/* Задание 6 из 6. Напишите запрос, который покажет количество всех пользователей из США. Это пользователи, у которых номер телефона начинается на +1. */
select COUNT(customer_id) as persons_from_usa_count
from car_shop.clients
where phone like '+1%';




