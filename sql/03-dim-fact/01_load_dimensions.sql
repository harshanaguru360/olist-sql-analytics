/* ===========================================================================
   01_load_dimensions.sql
   Transforms typed, de-duplicated rows out of staging into the dimensions.

   TRY_CAST is used on every conversion so a single bad value yields NULL
   rather than aborting the load. Empty strings (common in the date columns of
   the raw export) are turned into NULL with NULLIF before casting.

   Re-running is safe: dimensions are truncated, then the facts that reference
   them are rebuilt in the next script.
   =========================================================================== */

USE OlistAnalytics;
GO

DELETE FROM star.fact_order_items;
DELETE FROM star.fact_orders;
DELETE FROM star.dim_customer;
DELETE FROM star.dim_seller;
DELETE FROM star.dim_product;
DELETE FROM star.dim_geography;
DELETE FROM star.dim_date;
GO

/* ---- dim_date : one row per calendar day across the dataset window ------ */
WITH calendar AS (
    SELECT CAST('2016-01-01' AS DATE) AS d
    UNION ALL
    SELECT DATEADD(DAY, 1, d) FROM calendar WHERE d < '2018-12-31'
)
INSERT INTO star.dim_date
    (date_key, full_date, year, quarter, month, month_name, day, day_of_week, is_weekend)
SELECT
    (YEAR(d) * 10000) + (MONTH(d) * 100) + DAY(d),
    d,
    YEAR(d),
    DATEPART(QUARTER, d),
    MONTH(d),
    DATENAME(MONTH, d),
    DAY(d),
    DATEPART(WEEKDAY, d),
    CASE WHEN DATEPART(WEEKDAY, d) IN (1, 7) THEN 1 ELSE 0 END
FROM calendar
OPTION (MAXRECURSION 0);
GO

/* ---- dim_customer ------------------------------------------------------- */
INSERT INTO star.dim_customer (customer_id, customer_unique_id, zip_code_prefix, city, state)
SELECT
    customer_id,
    customer_unique_id,
    TRY_CAST(customer_zip_code_prefix AS INT),
    customer_city,
    customer_state
FROM staging.customers;
GO

/* ---- dim_seller --------------------------------------------------------- */
INSERT INTO star.dim_seller (seller_id, zip_code_prefix, city, state)
SELECT
    seller_id,
    TRY_CAST(seller_zip_code_prefix AS INT),
    seller_city,
    seller_state
FROM staging.sellers;
GO

/* ---- dim_product : join the English category translation in --------------- */
INSERT INTO star.dim_product (product_id, category_pt, category_en, weight_g, photos_qty)
SELECT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    TRY_CAST(p.product_weight_g AS INT),
    TRY_CAST(p.product_photos_qty AS INT)
FROM staging.products p
LEFT JOIN staging.category_translation t
       ON p.product_category_name = t.product_category_name;
GO

/* ---- dim_geography : every zip prefix seen on a customer or a seller ------
   Built from the customer and seller records rather than a separate
   geolocation feed, so it reflects the locations that actually appear in the
   order history. One row per zip prefix. */
INSERT INTO star.dim_geography (zip_code_prefix, city, state)
SELECT zip_code_prefix, MIN(city) AS city, MIN(state) AS state
FROM (
    SELECT TRY_CAST(customer_zip_code_prefix AS INT) AS zip_code_prefix,
           customer_city AS city, customer_state AS state
    FROM staging.customers
    UNION ALL
    SELECT TRY_CAST(seller_zip_code_prefix AS INT),
           seller_city, seller_state
    FROM staging.sellers
) z
WHERE zip_code_prefix IS NOT NULL
GROUP BY zip_code_prefix;
GO

PRINT 'Dimensions loaded.';
GO
