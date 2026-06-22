/* ===========================================================================
   Q2. Where do delivery delays cluster geographically?

   For each customer-state by seller-state pair we measure the late rate and
   the average days late. Pairs that ship long distances (a seller in SP to a
   customer in the north, say) are the usual offenders. Filtering to pairs with
   enough volume keeps the result trustworthy.
   =========================================================================== */

WITH order_lines AS (
    -- one row per (order, seller-state), so a multi-seller order is counted
    -- once per originating state
    SELECT DISTINCT
        fo.order_id,
        cust.state  AS customer_state,
        sell.state  AS seller_state,
        fo.is_late,
        fo.delay_days
    FROM star.fact_order_items fi
    JOIN star.fact_orders   fo   ON fo.order_key   = fi.order_key
    JOIN star.dim_customer  cust ON cust.customer_key = fo.customer_key
    JOIN star.dim_seller    sell ON sell.seller_key   = fi.seller_key
    WHERE fo.is_late IS NOT NULL
)
SELECT
    customer_state,
    seller_state,
    COUNT(*)                                            AS delivered_orders,
    SUM(CAST(is_late AS INT))                           AS late_orders,
    CAST(100.0 * SUM(CAST(is_late AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS late_rate_pct,
    CAST(AVG(CASE WHEN delay_days > 0 THEN delay_days END) AS DECIMAL(6,2)) AS avg_days_when_late
FROM order_lines
GROUP BY customer_state, seller_state
HAVING COUNT(*) >= 20
ORDER BY late_rate_pct DESC, delivered_orders DESC
OFFSET 0 ROWS FETCH FIRST 20 ROWS ONLY;
