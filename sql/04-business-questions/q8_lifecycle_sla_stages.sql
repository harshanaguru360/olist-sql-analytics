/* ===========================================================================
   Q8. Order lifecycle: where does the time go, and where are SLAs breached?

   An order moves purchase -> approved -> handed to carrier -> delivered. We
   measure the average duration of each leg, then compare total fulfilment time
   against the estimate the customer was shown. Splitting the legs shows whether
   delay lives in payment approval, seller handoff, or the carrier.
   =========================================================================== */

WITH legs AS (
    SELECT
        order_id,
        DATEDIFF(HOUR, purchase_ts, approved_ts)              AS approval_hours,
        DATEDIFF(HOUR, approved_ts, delivered_carrier_ts)     AS handoff_hours,
        DATEDIFF(HOUR, delivered_carrier_ts, delivered_cust_ts) AS carrier_hours,
        delivery_days,
        estimated_days,
        delay_days,
        is_late
    FROM star.fact_orders
    WHERE order_status = 'delivered'
      AND purchase_ts IS NOT NULL
      AND approved_ts IS NOT NULL
      AND delivered_carrier_ts IS NOT NULL
      AND delivered_cust_ts IS NOT NULL
)
SELECT
    COUNT(*)                                              AS delivered_orders,
    CAST(AVG(approval_hours) AS DECIMAL(8,1))             AS avg_approval_hours,
    CAST(AVG(handoff_hours)  AS DECIMAL(8,1))             AS avg_seller_handoff_hours,
    CAST(AVG(carrier_hours)  AS DECIMAL(8,1))             AS avg_carrier_hours,
    CAST(AVG(CAST(delivery_days AS DECIMAL(8,2))) AS DECIMAL(8,2))  AS avg_total_days,
    CAST(AVG(CAST(estimated_days AS DECIMAL(8,2))) AS DECIMAL(8,2)) AS avg_promised_days,
    CAST(100.0 * SUM(CAST(is_late AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS late_rate_pct,
    CAST(AVG(CASE WHEN delay_days > 0 THEN CAST(delay_days AS DECIMAL(8,2)) END)
         AS DECIMAL(8,2))                                 AS avg_days_late_when_late
FROM legs;
