/* ===========================================================================
   Q1. Which product categories drive the largest share of repeat purchases?

   A repeat customer is one whose customer_unique_id appears on more than one
   order. For each category we measure what share of its line items come from
   those repeat customers. Categories high on this metric are the ones worth
   protecting with loyalty and replenishment programs.
   =========================================================================== */

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT fo.order_id) AS order_count
    FROM star.fact_orders fo
    JOIN star.dim_customer c ON c.customer_key = fo.customer_key
    GROUP BY c.customer_unique_id
),
item_flags AS (
    SELECT
        dp.category_en,
        CASE WHEN co.order_count > 1 THEN 1 ELSE 0 END AS is_repeat_customer
    FROM star.fact_order_items fi
    JOIN star.fact_orders fo ON fo.order_key = fi.order_key
    JOIN star.dim_customer c ON c.customer_key = fo.customer_key
    JOIN customer_orders co  ON co.customer_unique_id = c.customer_unique_id
    JOIN star.dim_product dp ON dp.product_key = fi.product_key
)
SELECT
    category_en,
    COUNT(*)                                                AS total_items,
    SUM(is_repeat_customer)                                 AS repeat_items,
    CAST(100.0 * SUM(is_repeat_customer) / COUNT(*) AS DECIMAL(5,2)) AS repeat_share_pct
FROM item_flags
WHERE category_en IS NOT NULL
GROUP BY category_en
HAVING COUNT(*) >= 30          -- ignore thinly populated categories
ORDER BY repeat_share_pct DESC
OFFSET 0 ROWS FETCH FIRST 15 ROWS ONLY;
