/* ===========================================================================
   Q4. How does installment count relate to order value and dissatisfaction?

   Brazilian e-commerce leans heavily on installment payments. We bucket orders
   by value, cross them with installment bands, and within each cell measure the
   "1-star rate" (review_score = 1) as a proxy for a soured transaction. The
   question behind it: do long installment plans on small baskets correlate with
   unhappy customers?
   =========================================================================== */

WITH base AS (
    SELECT
        order_value,
        payment_installments,
        review_score,
        CASE
            WHEN order_value < 50   THEN '1. under 50'
            WHEN order_value < 100  THEN '2. 50 to 100'
            WHEN order_value < 200  THEN '3. 100 to 200'
            WHEN order_value < 500  THEN '4. 200 to 500'
            ELSE '5. 500 plus'
        END AS value_bucket,
        CASE
            WHEN payment_installments <= 1 THEN '1x'
            WHEN payment_installments <= 3 THEN '2 to 3x'
            WHEN payment_installments <= 6 THEN '4 to 6x'
            ELSE '7x plus'
        END AS installment_band
    FROM star.fact_orders
    WHERE order_value IS NOT NULL
      AND payment_installments IS NOT NULL
)
SELECT
    value_bucket,
    installment_band,
    COUNT(*)                                                   AS orders,
    CAST(AVG(order_value) AS DECIMAL(10,2))                    AS avg_order_value,
    SUM(CASE WHEN review_score = 1 THEN 1 ELSE 0 END)          AS one_star_orders,
    CAST(100.0 * SUM(CASE WHEN review_score = 1 THEN 1 ELSE 0 END)
         / NULLIF(SUM(CASE WHEN review_score IS NOT NULL THEN 1 ELSE 0 END), 0)
         AS DECIMAL(5,2))                                      AS one_star_rate_pct
FROM base
GROUP BY value_bucket, installment_band
ORDER BY value_bucket, installment_band;
