/* ===========================================================================
   Q3. What is the review-score lift from on-time delivery, by category?

   Within each category we compare the average review score of orders delivered
   on time against those delivered late. The gap (the "lift") isolates how much
   of customer satisfaction is driven by logistics rather than the product
   itself. Controlling by category stops a category mix effect from masking it.
   =========================================================================== */

WITH scored AS (
    SELECT
        dp.category_en,
        fo.is_late,
        fo.review_score
    FROM star.fact_orders fo
    JOIN star.fact_order_items fi ON fi.order_key = fo.order_key
    JOIN star.dim_product dp      ON dp.product_key = fi.product_key
    WHERE fo.review_score IS NOT NULL
      AND fo.is_late IS NOT NULL
      AND dp.category_en IS NOT NULL
),
by_cat AS (
    SELECT
        category_en,
        AVG(CASE WHEN is_late = 0 THEN CAST(review_score AS DECIMAL(4,2)) END) AS avg_score_on_time,
        AVG(CASE WHEN is_late = 1 THEN CAST(review_score AS DECIMAL(4,2)) END) AS avg_score_late,
        SUM(CASE WHEN is_late = 0 THEN 1 ELSE 0 END) AS n_on_time,
        SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) AS n_late
    FROM scored
    GROUP BY category_en
)
SELECT
    category_en,
    n_on_time,
    n_late,
    avg_score_on_time,
    avg_score_late,
    CAST(avg_score_on_time - avg_score_late AS DECIMAL(4,2)) AS on_time_lift
FROM by_cat
WHERE n_on_time >= 20 AND n_late >= 5      -- both arms need support
ORDER BY on_time_lift DESC;
