/* ===========================================================================
   03_create_star_schema.sql
   The modeled layer: five dimensions and two fact tables.

   Grain:
     fact_orders        one row per order
     fact_order_items   one row per order line (an order can have several)

   The two grains are deliberate. Order level answers customer, delivery, and
   payment questions cleanly; line level is needed for seller and product
   economics, where a single order spans multiple sellers and products.
   =========================================================================== */

USE OlistAnalytics;
GO

DROP TABLE IF EXISTS star.fact_order_items;
DROP TABLE IF EXISTS star.fact_orders;
DROP TABLE IF EXISTS star.dim_customer;
DROP TABLE IF EXISTS star.dim_seller;
DROP TABLE IF EXISTS star.dim_product;
DROP TABLE IF EXISTS star.dim_geography;
DROP TABLE IF EXISTS star.dim_date;
GO

/* ---- Dimensions -------------------------------------------------------- */

CREATE TABLE star.dim_date (
    date_key     INT          NOT NULL PRIMARY KEY,   -- yyyymmdd
    full_date    DATE         NOT NULL,
    year         SMALLINT     NOT NULL,
    quarter      TINYINT      NOT NULL,
    month        TINYINT      NOT NULL,
    month_name   VARCHAR(12)  NOT NULL,
    day          TINYINT      NOT NULL,
    day_of_week  TINYINT      NOT NULL,
    is_weekend   BIT          NOT NULL
);

CREATE TABLE star.dim_customer (
    customer_key        INT IDENTITY(1,1) PRIMARY KEY,
    customer_id         NVARCHAR(64) NOT NULL,
    customer_unique_id  NVARCHAR(64) NOT NULL,
    zip_code_prefix     INT          NULL,
    city                NVARCHAR(128) NULL,
    state               NVARCHAR(8)  NULL
);

CREATE TABLE star.dim_seller (
    seller_key       INT IDENTITY(1,1) PRIMARY KEY,
    seller_id        NVARCHAR(64) NOT NULL,
    zip_code_prefix  INT          NULL,
    city             NVARCHAR(128) NULL,
    state            NVARCHAR(8)  NULL
);

CREATE TABLE star.dim_product (
    product_key    INT IDENTITY(1,1) PRIMARY KEY,
    product_id     NVARCHAR(64) NOT NULL,
    category_pt    NVARCHAR(128) NULL,
    category_en    NVARCHAR(128) NULL,
    weight_g       INT          NULL,
    photos_qty     INT          NULL
);

CREATE TABLE star.dim_geography (
    geography_key   INT IDENTITY(1,1) PRIMARY KEY,
    zip_code_prefix INT          NOT NULL,
    city            NVARCHAR(128) NULL,
    state           NVARCHAR(8)  NULL
);

/* ---- Facts ------------------------------------------------------------- */

CREATE TABLE star.fact_orders (
    order_key            INT IDENTITY(1,1) PRIMARY KEY,
    order_id             NVARCHAR(64) NOT NULL,
    customer_key         INT          NULL REFERENCES star.dim_customer(customer_key),
    order_status         NVARCHAR(32) NULL,
    purchase_date_key    INT          NULL REFERENCES star.dim_date(date_key),
    purchase_ts          DATETIME2    NULL,
    approved_ts          DATETIME2    NULL,
    delivered_carrier_ts DATETIME2    NULL,
    delivered_cust_ts    DATETIME2    NULL,
    estimated_ts         DATETIME2    NULL,
    delivery_days        INT          NULL,   -- purchase to customer delivery
    estimated_days       INT          NULL,   -- purchase to estimated date
    delay_days           INT          NULL,   -- actual minus estimated (positive = late)
    is_late              BIT          NULL,
    payment_type         NVARCHAR(32) NULL,
    payment_installments INT          NULL,
    payment_value        DECIMAL(12,2) NULL,
    review_score         TINYINT      NULL,
    item_count           INT          NULL,
    order_value          DECIMAL(12,2) NULL
);

CREATE TABLE star.fact_order_items (
    order_item_key   INT IDENTITY(1,1) PRIMARY KEY,
    order_id         NVARCHAR(64) NOT NULL,
    order_key        INT          NULL REFERENCES star.fact_orders(order_key),
    order_item_id    INT          NULL,
    product_key      INT          NULL REFERENCES star.dim_product(product_key),
    seller_key       INT          NULL REFERENCES star.dim_seller(seller_key),
    purchase_date_key INT         NULL REFERENCES star.dim_date(date_key),
    price            DECIMAL(12,2) NULL,
    freight_value    DECIMAL(12,2) NULL
);
GO

/* Indexes that match the join and filter patterns in 04-business-questions */
CREATE INDEX ix_fact_orders_customer  ON star.fact_orders(customer_key);
CREATE INDEX ix_fact_orders_date      ON star.fact_orders(purchase_date_key);
CREATE INDEX ix_fact_orders_status    ON star.fact_orders(order_status);
CREATE INDEX ix_fact_items_order      ON star.fact_order_items(order_key);
CREATE INDEX ix_fact_items_seller     ON star.fact_order_items(seller_key);
CREATE INDEX ix_fact_items_product    ON star.fact_order_items(product_key);
GO
