/* ===========================================================================
   02_create_staging_tables.sql
   Landing tables that mirror the nine raw Olist CSVs one for one.

   Design choice: every column is NVARCHAR here. Loading text first and casting
   types later (in the dim/fact step) means a single malformed value or an empty
   date string never aborts the whole bulk load. The real typing and validation
   happen on the way into the star schema.
   =========================================================================== */

USE OlistAnalytics;
GO

DROP TABLE IF EXISTS staging.customers;
DROP TABLE IF EXISTS staging.sellers;
DROP TABLE IF EXISTS staging.products;
DROP TABLE IF EXISTS staging.category_translation;
DROP TABLE IF EXISTS staging.orders;
DROP TABLE IF EXISTS staging.order_items;
DROP TABLE IF EXISTS staging.order_payments;
DROP TABLE IF EXISTS staging.order_reviews;
GO

CREATE TABLE staging.customers (
    customer_id              NVARCHAR(64),
    customer_unique_id       NVARCHAR(64),
    customer_zip_code_prefix NVARCHAR(16),
    customer_city            NVARCHAR(128),
    customer_state           NVARCHAR(8)
);

CREATE TABLE staging.sellers (
    seller_id              NVARCHAR(64),
    seller_zip_code_prefix NVARCHAR(16),
    seller_city            NVARCHAR(128),
    seller_state           NVARCHAR(8)
);

CREATE TABLE staging.products (
    product_id                 NVARCHAR(64),
    product_category_name      NVARCHAR(128),
    product_name_lenght        NVARCHAR(16),
    product_description_lenght NVARCHAR(16),
    product_photos_qty         NVARCHAR(16),
    product_weight_g           NVARCHAR(16),
    product_length_cm          NVARCHAR(16),
    product_height_cm          NVARCHAR(16),
    product_width_cm           NVARCHAR(16)
);

CREATE TABLE staging.category_translation (
    product_category_name         NVARCHAR(128),
    product_category_name_english NVARCHAR(128)
);

CREATE TABLE staging.orders (
    order_id                      NVARCHAR(64),
    customer_id                   NVARCHAR(64),
    order_status                  NVARCHAR(32),
    order_purchase_timestamp      NVARCHAR(32),
    order_approved_at             NVARCHAR(32),
    order_delivered_carrier_date  NVARCHAR(32),
    order_delivered_customer_date NVARCHAR(32),
    order_estimated_delivery_date NVARCHAR(32)
);

CREATE TABLE staging.order_items (
    order_id            NVARCHAR(64),
    order_item_id       NVARCHAR(16),
    product_id          NVARCHAR(64),
    seller_id           NVARCHAR(64),
    shipping_limit_date NVARCHAR(32),
    price               NVARCHAR(32),
    freight_value       NVARCHAR(32)
);

CREATE TABLE staging.order_payments (
    order_id             NVARCHAR(64),
    payment_sequential   NVARCHAR(16),
    payment_type         NVARCHAR(32),
    payment_installments NVARCHAR(16),
    payment_value        NVARCHAR(32)
);

CREATE TABLE staging.order_reviews (
    review_id               NVARCHAR(64),
    order_id                NVARCHAR(64),
    review_score            NVARCHAR(8),
    review_comment_title    NVARCHAR(256),
    review_comment_message  NVARCHAR(MAX),
    review_creation_date    NVARCHAR(32),
    review_answer_timestamp NVARCHAR(32)
);
GO
