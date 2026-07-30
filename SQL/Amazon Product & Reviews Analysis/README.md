# Amazon Product & Reviews — SQL Analysis

**Tools:** MySQL 5.7 (MySQL Workbench) · Python (pandas, for data cleaning)
**Dataset:** [Amazon Sales Dataset](https://www.kaggle.com/) — 1,465 raw product listings with embedded review data

## Overview

This project takes a messy, denormalized flat-file export of Amazon product and review data and turns it into a proper relational database — then uses SQL to answer real business questions about pricing, ratings, and review patterns.

The raw dataset packed multiple reviews into single comma-separated cells per product row (`user_id`, `review_id`, `user_name` each held up to 8 values per row). The core of this project was designing a clean two-table schema, handling the data quality problems that came with the split, and writing SQL — from basic filtering through joins, subqueries, and rank simulation — to extract insights from it.

## Schema

**`products`** (1,351 rows — deduplicated from 1,465 raw rows)
| Column | Type | Notes |
|---|---|---|
| product_id | VARCHAR(20) | Primary key |
| product_name | VARCHAR(500) | |
| category_main / category_sub | VARCHAR | Split from a single `|`-delimited category string |
| discounted_price / actual_price | DECIMAL(10,2) | Cleaned from `₹1,099` text format |
| discount_percentage | DECIMAL(5,2) | Cleaned from `64%` text format |
| rating | DECIMAL(3,2) | |
| rating_count | INT | |
| about_product | TEXT | |

**`reviewers`** (9,269 rows)
| Column | Type | Notes |
|---|---|---|
| review_id | VARCHAR(20) | Primary key |
| product_id | VARCHAR(20) | Foreign key → products |
| user_id | VARCHAR(50) | |
| user_name | VARCHAR(200) | |

## SQL Queries

### Database & Table Setup

```sql
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
```

### Top-Rated Products with Meaningful Review Volume

```sql
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
```

### Which Category Has the Deepest Average Discounts?

```sql
SELECT 
    category_main,
    COUNT(*) AS num_products,
    ROUND(AVG(discount_percentage), 1) AS avg_discount,
    ROUND(AVG(rating), 2) AS avg_rating
FROM products
WHERE rating > 0
GROUP BY category_main
ORDER BY avg_discount DESC;
```

### Most-Reviewed Products (by actual review count in the dataset, not the site's aggregate `rating_count`)

```sql
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
```

### Reviewers Who Show Up Most Often Across Different Products

```sql
SELECT 
    user_name,
    user_id,
    COUNT(DISTINCT product_id) AS products_reviewed
FROM reviewers
GROUP BY user_id, user_name
ORDER BY products_reviewed DESC
LIMIT 10;
```

### Products in the Catalog with Zero Linked Reviews

```sql
SELECT 
    p.product_id,
    p.product_name,
    p.category_main,
    p.rating_count
FROM products p
LEFT JOIN reviewers r ON p.product_id = r.product_id
WHERE r.review_id IS NULL;
```

### Products Priced Above Their Own Category's Average

```sql
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
```

### Top 3 Highest-Rated Products Within Each Category (session-variable rank simulation)

```sql
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
```

### Price vs. Category Average (correlated subqueries instead of window functions)

```sql
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
```

## Data Cleaning Notes

A few real-world data issues came up during import — documenting them here since identifying and resolving them was as much a part of this project as the SQL itself:

- **Comma-packed multi-value fields.** `user_id` and `review_id` split reliably (0 mismatches across all rows) since they're structured tokens. `review_title` and `review_content` could **not** be split reliably — the review text itself contains unescaped commas, so ~33% of rows would misalign if split naively. Those two fields were excluded from the relational schema rather than force-fit with bad data.
- **114 exact duplicate rows** in the source file, resolved by deduplicating on `product_id`.
- **Unicode and escaping issues** (full-width brackets, curly quotes, a literal backslash in one username) broke MySQL's CSV import parser partway through, causing silent partial imports (1287 then 1348 of 1351 rows) before being fully resolved.
- **3 rows with missing rating/rating_count** — filled with `0` to satisfy the numeric column type, but treated as `NULL`-equivalent in all analysis (`WHERE rating > 0`) rather than counted as real values.
- **MySQL 5.7 has no window functions.** `RANK() OVER (...)` (MySQL 8.0+) isn't available on this server version, so ranking-within-category was implemented using session variables instead — a good exercise in understanding what window functions abstract away.

## Key Findings

**1. High ratings hold up at scale, not just on small samples.**
Several products hit 4.8–5.0 ratings across very different review volumes — a wireless mouse at 5.0 (23 reviews) sits alongside a water heater faucet at 4.8 across 53,803 reviews. Ratings staying high at both small and large volumes points to genuine product quality rather than a handful of lucky early reviews.

**2. Computers&Accessories and Electronics dominate the catalog.**
Of 1,351 products, 375 fall under Computers&Accessories and 490 under Electronics — over 60% of the entire catalog combined. Computers&Accessories also carries a deep average discount (53.2%).

**3. Review depth in this dataset caps at 9 per product.**
Every top "most-reviewed" product tops out at exactly 9 linked reviews — a structural feature of the source data (Amazon surfaces a small curated review sample per listing) rather than a data error. The site-wide `rating_count` field is a separate, much larger aggregate.

**4. Reviewer overlap is minimal.**
The most active reviewer appears across just 5 different products; most reviewers in the dataset appear only once. No evidence of a small group of reviewers dominating the sample.

**5. Ten high-profile products have zero linked reviews.**
A `LEFT JOIN` between `products` and `reviewers` surfaced 10 products — some with `rating_count` as high as 426,973 — with no individual review rows in the dataset. This is a genuine completeness gap in the original source data, flagged here rather than hidden.

**6. Price outliers distort category averages.**
167 products (~12% of the catalog) are priced above their own category's average. In Computers&Accessories, a handful of laptops and monitors (up to ₹37,247) sit in a category whose average price (₹947) is otherwise dragged down by the sheer volume of cheap cables and accessories.

## SQL Techniques Used

`WHERE` filtering · `GROUP BY` aggregation · `INNER JOIN` / `LEFT JOIN` · `COUNT(DISTINCT ...)` · correlated subqueries · rank simulation via session variables (MySQL 5.7 workaround for window functions)

## Next Steps

- Explore `review_title` / `review_content` with a more robust parser (e.g. regex-based splitting anchored on the review_id pattern) to recover per-review text safely.
- Extend with a Python/pandas notebook for visualization of the findings above.
