/* ===========================================================================
   02_load_facts.sql
   Builds fact_orders (one row per order) and fact_order_items (one per line).

   fact_orders pre-computes the delivery measures the analysis leans on:
     delivery_days   purchase to actual customer delivery
     estimated_days  purchase to the promised date
     delay_days      actual minus promised (positive means late)
     is_late         1 when delivered after the promised date
   Pre-computing these once keeps the business-question queries readable.

   Payments and reviews are folded onto the order grain. Where an order has
   several payment rows, the values are summed and the dominant type kept.
   =========================================================================== */

USE OlistAnalytics;
GO

/* ---- fact_orders -------------------------------------------------------- */
WITH pay AS (
    SELECT
        order_id,
        SUM(TRY_CAST(payment_value AS DECIMAL(12,2)))         AS payment_value,
        MAX(TRY_CAST(payment_installments AS INT))            AS payment_installments,
        MIN(payment_type)                                     AS payment_type
    FROM staging.order_payments
    GROUP BY order_id
),
rev AS (
    -- keep one review score per order (the first by creation date)
    SELECT order_id, review_score
    FROM (
        SELECT
            order_id,
            TRY_CAST(review_score AS TINYINT) AS review_score,
            ROW_NUMBER() OVER (PARTITION BY order_id
                               ORDER BY review_creation_date) AS rn
        FROM staging.order_reviews
    ) z
    WHERE rn = 1
),
items AS (
    SELECT
        order_id,
        COUNT(*)                                          AS item_count,
        SUM(TRY_CAST(price AS DECIMAL(12,2))
            + TRY_CAST(freight_value AS DECIMAL(12,2)))   AS items_value
    FROM staging.order_items
    GROUP BY order_id
)
INSERT INTO star.fact_orders (
    order_id, customer_key, order_status, purchase_date_key,
    purchase_ts, approved_ts, delivered_carrier_ts, delivered_cust_ts, estimated_ts,
    delivery_days, estimated_days, delay_days, is_late,
    payment_type, payment_installments, payment_value,
    review_score, item_count, order_value
)
SELECT
    o.order_id,
    c.customer_key,
    o.order_status,
    CASE WHEN p_ts.purchase_ts IS NOT NULL
         THEN (YEAR(p_ts.purchase_ts) * 10000)
              + (MONTH(p_ts.purchase_ts) * 100)
              + DAY(p_ts.purchase_ts) END                       AS purchase_date_key,
    p_ts.purchase_ts,
    TRY_CAST(NULLIF(o.order_approved_at, '') AS DATETIME2)      AS approved_ts,
    TRY_CAST(NULLIF(o.order_delivered_carrier_date, '') AS DATETIME2) AS delivered_carrier_ts,
    d_ts.delivered_ts,
    e_ts.estimated_ts,
    CASE WHEN d_ts.delivered_ts IS NOT NULL
         THEN DATEDIFF(DAY, p_ts.purchase_ts, d_ts.delivered_ts) END AS delivery_days,
    CASE WHEN e_ts.estimated_ts IS NOT NULL
         THEN DATEDIFF(DAY, p_ts.purchase_ts, e_ts.estimated_ts) END AS estimated_days,
    CASE WHEN d_ts.delivered_ts IS NOT NULL AND e_ts.estimated_ts IS NOT NULL
         THEN DATEDIFF(DAY, e_ts.estimated_ts, d_ts.delivered_ts) END AS delay_days,
    CASE WHEN d_ts.delivered_ts IS NOT NULL AND e_ts.estimated_ts IS NOT NULL
         THEN CASE WHEN d_ts.delivered_ts > e_ts.estimated_ts THEN 1 ELSE 0 END END AS is_late,
    pay.payment_type,
    pay.payment_installments,
    pay.payment_value,
    rev.review_score,
    items.item_count,
    COALESCE(pay.payment_value, items.items_value)             AS order_value
FROM staging.orders o
CROSS APPLY (SELECT TRY_CAST(NULLIF(o.order_purchase_timestamp, '') AS DATETIME2) AS purchase_ts) p_ts
CROSS APPLY (SELECT TRY_CAST(NULLIF(o.order_delivered_customer_date, '') AS DATETIME2) AS delivered_ts) d_ts
CROSS APPLY (SELECT TRY_CAST(NULLIF(o.order_estimated_delivery_date, '') AS DATETIME2) AS estimated_ts) e_ts
LEFT JOIN star.dim_customer c ON c.customer_id = o.customer_id
LEFT JOIN pay   ON pay.order_id   = o.order_id
LEFT JOIN rev   ON rev.order_id   = o.order_id
LEFT JOIN items ON items.order_id = o.order_id;
GO

/* ---- fact_order_items --------------------------------------------------- */
INSERT INTO star.fact_order_items (
    order_id, order_key, order_item_id, product_key, seller_key,
    purchase_date_key, price, freight_value
)
SELECT
    i.order_id,
    fo.order_key,
    TRY_CAST(i.order_item_id AS INT),
    dp.product_key,
    ds.seller_key,
    fo.purchase_date_key,
    TRY_CAST(i.price AS DECIMAL(12,2)),
    TRY_CAST(i.freight_value AS DECIMAL(12,2))
FROM staging.order_items i
LEFT JOIN star.fact_orders fo ON fo.order_id   = i.order_id
LEFT JOIN star.dim_product dp ON dp.product_id = i.product_id
LEFT JOIN star.dim_seller  ds ON ds.seller_id  = i.seller_id;
GO

PRINT 'Facts loaded.';

SELECT 'fact_orders' AS table_name, COUNT(*) AS rows FROM star.fact_orders
UNION ALL SELECT 'fact_order_items', COUNT(*) FROM star.fact_order_items;
GO
