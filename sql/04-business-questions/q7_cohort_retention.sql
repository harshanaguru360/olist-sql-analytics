/* ===========================================================================
   Q7. Cohort retention: do acquired customers come back?

   Each customer belongs to the cohort of the month of their first purchase.
   We then measure how many placed a later order in the windows 1 to 3, 4 to 6
   and 7 to 12 months after acquisition. Olist is mostly a one-purchase
   marketplace, so the absolute numbers are expected to be low; the point is the
   shape across cohorts and the method.
   =========================================================================== */

WITH first_order AS (
    SELECT
        c.customer_unique_id,
        MIN(fo.purchase_ts) AS first_ts
    FROM star.fact_orders fo
    JOIN star.dim_customer c ON c.customer_key = fo.customer_key
    WHERE fo.purchase_ts IS NOT NULL
    GROUP BY c.customer_unique_id
),
orders_with_cohort AS (
    SELECT
        f.customer_unique_id,
        DATEFROMPARTS(YEAR(f.first_ts), MONTH(f.first_ts), 1) AS cohort_month,
        DATEDIFF(MONTH, f.first_ts, fo.purchase_ts)            AS months_since_first
    FROM first_order f
    JOIN star.dim_customer c ON c.customer_unique_id = f.customer_unique_id
    JOIN star.fact_orders fo ON fo.customer_key = c.customer_key
    WHERE fo.purchase_ts IS NOT NULL
)
SELECT
    cohort_month,
    COUNT(DISTINCT customer_unique_id)                                       AS cohort_size,
    COUNT(DISTINCT CASE WHEN months_since_first BETWEEN 1 AND 3
                        THEN customer_unique_id END)                         AS returned_m1_m3,
    COUNT(DISTINCT CASE WHEN months_since_first BETWEEN 4 AND 6
                        THEN customer_unique_id END)                         AS returned_m4_m6,
    COUNT(DISTINCT CASE WHEN months_since_first BETWEEN 7 AND 12
                        THEN customer_unique_id END)                         AS returned_m7_m12,
    CAST(100.0 * COUNT(DISTINCT CASE WHEN months_since_first BETWEEN 1 AND 3
                        THEN customer_unique_id END)
         / COUNT(DISTINCT customer_unique_id) AS DECIMAL(5,2))               AS retention_m1_m3_pct
FROM orders_with_cohort
GROUP BY cohort_month
ORDER BY cohort_month;
