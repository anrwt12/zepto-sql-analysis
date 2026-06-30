/*
=========================================
Project : Zepto Product Analysis
Database : MySQL

Objective:
Analyze Zepto's product catalog to understand
product pricing,
discounts,
inventory,
stock availability,
category performance,
and business insights.

Skills Used:
- SELECT
- WHERE
- GROUP BY
- HAVING
- ORDER BY
- Aggregate Functions
- CASE
- JOINS
- Subqueries
- Window Functions
=========================================
*/



CREATE DATABASE zepto_db;
USE zepto_db;

CREATE TABLE zepto_products (
    Category VARCHAR(100),
    name VARCHAR(255),
    mrp INT,
    discountPercent INT,
    availableQuantity INT,
    discountedSellingPrice INT,
    weightInGms INT,
    outOfStock BOOLEAN,
    quantity INT
);

SHOW VARIABLES LIKE 'local_infile';

LOAD DATA LOCAL INFILE 'C:/Users/lenovo/Downloads/zepto_v2_utf8.csv'
INTO TABLE zepto_products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
 
 SELECT COUNT(*) AS total_records
FROM zepto_products;

SELECT COUNT(DISTINCT name) AS unique_products
FROM zepto_products;
 
 
/*-- ===========================
-- Data Cleaning
-- ===========================

-- Check NULL values

-- Check Duplicate Products

-- Check Invalid Prices

-- Check Negative Quantity

-- Check Selling Price > MRP 
*/

-- ===================
-- Basic Exploration
-- ===================

-- 1 What is the total number of products available?
select count(*) as total_products
from  zepto_products;

-- 2 What does the dataset look like?
select * from zepto_products
limit 10;


-- 3 What are the different product categories?
select distinct Category from zepto_products
order by category;

-- 4 How many unique categories does Zepto have?
select count(distinct Category) as total_category from zepto_products;


-- 5 How many products are present in each category?
select Category , count(*) as total_products 
from zepto_products
group by Category 
order by total_products DESC
;

-- 6 Are there any duplicate product names?
select name , count(*) as 
duplicate_products from zepto_products
group by name 
having count(*)>1
;


-- 7 Are there any NULL values? 
SELECT *
FROM zepto_products
WHERE Category IS NULL
   OR name IS NULL
   OR mrp IS NULL
   OR discountPercent IS NULL
   OR availableQuantity IS NULL
   OR discountedSellingPrice IS NULL
   OR weightInGms IS NULL
   OR outOfStock IS NULL
   OR quantity IS NULL;
   
   SELECT COUNT(*) AS null_mrp
FROM zepto_products
WHERE mrp IS NULL;


-- ===================
-- Category Analysis
-- ===================

-- 8 Are there any products where the Selling Price is greater than the MRP?
select category , name , mrp ,discountedSellingPrice from zepto_products
where discountedSellingPrice > mrp;


-- 9: What is the average discount percentage for each category?
select category ,round(avg(discountPercent),2) as average_discount_percentage from  zepto_products
group by  category
order by  average_discount_percentage desc;


 -- 10 Which category generates the highest total inventory value?
select category ,  SUM(availableQuantity * discountedSellingPrice) AS total_inventory_value   from zepto_products
group by  category
order by total_inventory_value  desc
 limit 10 ;
 
 -- Insight:
-- Categories with higher inventory value require better inventory planning.
 
 -- 11 Which products have a discount percentage greater than the average discount percentage of all products?
 select category , name ,discountPercent from zepto_products  where discountPercent
 > (select avg(discountPercent) as overall_average_discount  from zepto_products )
 order by discountPercent desc;
 
 -- Insight:
-- Products with discounts above the overall average are useful for promotional campaigns.
 
 -- 12 Find the products that have the maximum MRP in each category.
select p.Category ,
p.name,p.mrp  from zepto_products p
join 
(
SELECT category,
       MAX(mrp) AS maximum_mrp
FROM zepto_products
GROUP BY category
)m
 on 
 p.Category =m.Category 
AND p.mrp = m.maximum_mrp
ORDER BY p.mrp DESC;


-- ===================
-- Pricing Analysis
-- ===================

-- 13 Which are the Top 5 categories with the highest average selling price?
select Category ,  round(avg(discountedSellingPrice),2) as average_selling_price from zepto_products
group by Category 
order by average_selling_price desc limit 5;

-- 14 Find the top 10 products with the highest discount amount.
select category , name ,mrp ,discountedSellingPrice , (mrp -discountedSellingPrice) as discount_amount
from zepto_products
order by discount_amount  desc
 limit 10 ;


/* 15Classify products based on their discount percentage.
Rules:
Discount ≥ 50% → 'High Discount'
Discount 30% to 49% → 'Medium Discount'
Discount < 30% → 'Low Discount'
*/
select Category, name, discountPercent ,
case
when  discountPercent >=50  then 'High Discount'
when  discountPercent >= 30 then  'Medium Discount'
else 'Low Discount'
end discount_level
from zepto_products;

-- 16 Find all categories that have more than 100 products.
select category ,  count(*) as total_products
from  zepto_products
group by category 
having total_products >100 
order by total_products desc
;


-- 17 Find the Top 3 products in each category based on discount amount
SELECT category,name,mrp,discountedSellingPrice,
    (mrp - discountedSellingPrice) AS discount_amount
FROM
(SELECT
        category,name,mrp,
        discountedSellingPrice,
        (mrp - discountedSellingPrice) AS discount_amount,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY (mrp - discountedSellingPrice) DESC
        ) AS  product_rank
    FROM zepto_products
) ranked_products
WHERE  product_rank <= 3
ORDER BY category, discount_amount DESC;


-- 18 Which products are priced significantly higher than the average selling price of their category?
select p.Category,p.name,p.discountedSellingPrice
 from zepto_products p 
 join ( select Category, avg(discountedSellingPrice) as category_average_selling_price
  FROM zepto_products 
  group by Category) c
  on p.Category = c.Category
  where p.discountedSellingPrice >c.category_average_selling_price ;
  
  -- 19 Which products have the highest inventory value?
  select category , name ,
  availableQuantity,discountedSellingPrice,
  (availableQuantity*discountedSellingPrice)  as inventory_value from zepto_products
  order by inventory_value desc
LIMIT 10;


-- ===================
-- Inventory Analysis
-- ===================
  
  -- 20. Which high-value products are currently out of stock?
select category , name , mrp ,outOfStock  ,discountedSellingPrice from zepto_products
where outOfStock = true   AND discountedSellingPrice > 500
ORDER BY mrp DESC;

-- 21. Which categories have the highest percentage of out-of-stock products?
select
    category,
    count(*) AS total_products,
    Sum(CASE WHEN outOfStock = TRUE then 1 ELSE 0 END) AS out_of_stock_products,
    Round(
        SUM(CASE WHEN outOfStock = TRUE then 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS out_of_stock_percentage
from zepto_products
group by category
ORDER BY out_of_stock_percentage desc;

-- Insight:
-- High out-of-stock percentages may indicate strong demand or poor stock management.

-- 22. Which categories contribute the highest percentage of total inventory value?
select Category ,
sum(availableQuantity*discountedSellingPrice) as total_inventory_value,
round(sum(availableQuantity*discountedSellingPrice) *100 /
(select sum(availableQuantity*discountedSellingPrice) 
from zepto_products),2)as inventory_contribution_percentage
from zepto_products
group by  Category
 order by inventory_contribution_percentage desc;
 
 -- 23 Which products offer the best value for money (lowest price per gram)?
 select category , name ,discountedSellingPrice,weightInGms,
 round(discountedSellingPrice/weightInGms,3)
 as price_per_gram
 from zepto_products
WHERE weightInGms > 0
ORDER BY price_per_gram ASC
LIMIT 10;


-- 24. Which categories have the highest average MRP?
select category , round(avg(mrp),2) as average_mrp from  zepto_products
group by  category
order by  average_mrp desc limit 10;

-- 25. Which category has the widest price range?
select category , MAX(mrp) AS highest_mrp,
 MIN(mrp) AS lowest_mrp,
    (max(mrp)- min(mrp) )as price_range
from  zepto_products
group by category
order by price_range desc;

/*
=========================================
Project Summary

✔ Analyzed 3000+ products

✔ Studied category performance

✔ Compared pricing across categories

✔ Calculated inventory value

✔ Identified high-discount products

✔ Detected duplicate records

✔ Found out-of-stock trends

✔ Skills Demonstrated

✔ Data Exploration

✔ Data Cleaning

✔ Aggregate Functions

✔ GROUP BY & HAVING

✔ CASE Statements

✔ INNER JOIN

✔ Subqueries

✔ Window Functions

✔ Business-Oriented SQL Analysis

✔ Used Window Functions

=========================================
*/


