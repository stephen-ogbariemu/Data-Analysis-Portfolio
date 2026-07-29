CREATE DATABASE amazon_sales;
USE amazon_sales;

CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(500),
    category_main VARCHAR(100),
    category_sub VARCHAR(200),
    discounted_price DECIMAL(10,2),
    actual_price DECIMAL(10,2),
    discount_percentage DECIMAL(5,2),
    rating DECIMAL(3,2),
    rating_count INT,
    about_product TEXT
);

SELECT COUNT(*) AS Total_row FROM products;
CREATE TABLE reviewers (
    review_id VARCHAR(20) PRIMARY KEY,
    product_id VARCHAR(20),
    user_id VARCHAR(50),
    user_name VARCHAR(200),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
SELECT p.product_name, r.user_name, r.review_id
FROM products p
JOIN reviewers r ON p.product_id = r.product_id
LIMIT 5;
-- Top-rated products with meaningful review volume
SELECT 
    product_name,
    category_main,
    rating,
    rating_count,
    discounted_price,
    discount_percentage
FROM products
WHERE rating > 0
ORDER BY rating DESC, rating_count DESC
LIMIT 10;
-- Which category has the deepest average discounts?
SELECT 
    category_main,
    COUNT(*) AS num_products,
    ROUND(AVG(discount_percentage), 1) AS avg_discount,
    ROUND(AVG(rating), 2) AS avg_rating
FROM products
WHERE rating > 0
GROUP BY category_main
ORDER BY avg_discount DESC;
-- Most-reviewed products (by actual review count in our data, not the site's aggregate rating_count)
SELECT 
    p.product_name,
    p.category_main,
    p.rating,
    COUNT(r.review_id) AS reviews_in_dataset
FROM products p
JOIN reviewers r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name, p.category_main, p.rating
ORDER BY reviews_in_dataset DESC
LIMIT 10;
-- Which reviewers show up most often across different products
SELECT 
    user_name,
    user_id,
    COUNT(DISTINCT product_id) AS products_reviewed
FROM reviewers
GROUP BY user_id, user_name
ORDER BY products_reviewed DESC
LIMIT 10;
-- Products that made it into the catalog but have zero linked reviews
SELECT 
    p.product_id,
    p.product_name,
    p.category_main,
    p.rating_count
FROM products p
LEFT JOIN reviewers r ON p.product_id = r.product_id
WHERE r.review_id IS NULL;

-- Products priced above their own category's average
SELECT 
    p.product_name,
    p.category_main,
    p.discounted_price,
    (SELECT ROUND(AVG(discounted_price), 2)
     FROM products p2
     WHERE p2.category_main = p.category_main) AS category_avg_price
FROM products p
WHERE p.discounted_price > (
    SELECT AVG(discounted_price)
    FROM products p2
    WHERE p2.category_main = p.category_main
)
ORDER BY p.category_main, p.discounted_price DESC
LIMIT 15;

-- Top 3 highest-rated products within each category
SET @rank = 0, @prev_cat = '';
SELECT product_name, category_main, rating, rating_count, rnk
FROM (
    SELECT 
        product_name,
        category_main,
        rating,
        rating_count,
        @rank := IF(@prev_cat = category_main, @rank + 1, 1) AS rnk,
        @prev_cat := category_main
    FROM products
    WHERE rating > 0
    ORDER BY category_main, rating DESC, rating_count DESC
) ranked
WHERE rnk <= 3;

-- Price vs. category average, using correlated subqueries instead of window functions
SELECT 
    p.product_name,
    p.category_main,
    p.rating,
    p.discounted_price,
    (SELECT MAX(discounted_price) FROM products p2 WHERE p2.category_main = p.category_main) AS category_max_price,
    p.discounted_price - (SELECT AVG(discounted_price) FROM products p2 WHERE p2.category_main = p.category_main) AS diff_from_cat_avg
FROM products p
WHERE p.rating > 0
ORDER BY p.category_main, p.rating DESC
LIMIT 20;
