/* ===========================================================================
   Q5. RFM segmentation, and what share of revenue the top customers drive.

   Recency, Frequency and Monetary value are scored 1 to 5 per customer with
   NTILE, the standard quintile approach. The combined score names a segment.
   The second query answers the revenue-concentration question directly: what
   fraction of total revenue comes from the top monetary decile.

   Recency is measured against the latest purchase date in the data, so the
   result is stable regardless of when the query is run.
   =========================================================================== */

WITH anchor AS (
    SELECT MAX(purchase_ts) AS as_of FROM star.fact_orders WHERE purchase_ts IS NOT NULL
),
customer_rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF(DAY, MAX(fo.purchase_ts), (SELECT as_of FROM anchor)) AS recency_days,
        COUNT(DISTINCT fo.order_id)                                    AS frequency,
        SUM(fo.order_value)                                            AS monetary
    FROM star.fact_orders fo
    JOIN star.dim_customer c ON c.customer_key = fo.customer_key
    WHERE fo.purchase_ts IS NOT NULL AND fo.order_value IS NOT NULL
    GROUP BY c.customer_unique_id
),
scored AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        -- low recency is better, so reverse the order for the R score
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score
    FROM customer_rfm
)
SELECT
    r_score, f_score, m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_cell,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 2                  THEN 'Loyal'
        WHEN r_score >= 4                                   THEN 'Recent / new'
        WHEN r_score <= 2 AND f_score >= 4                  THEN 'At risk, high value'
        WHEN r_score <= 2                                   THEN 'Lapsed'
        ELSE 'Mid'
    END                              AS segment,
    COUNT(*)                         AS customers,
    CAST(SUM(monetary) AS DECIMAL(14,2)) AS segment_revenue
FROM scored
GROUP BY r_score, f_score, m_score
ORDER BY segment_revenue DESC;


/* ---- Revenue concentration: top monetary decile vs the rest ------------- */
WITH customer_rev AS (
    SELECT
        c.customer_unique_id,
        SUM(fo.order_value) AS monetary
    FROM star.fact_orders fo
    JOIN star.dim_customer c ON c.customer_key = fo.customer_key
    WHERE fo.order_value IS NOT NULL
    GROUP BY c.customer_unique_id
),
decile AS (
    SELECT
        customer_unique_id,
        monetary,
        NTILE(10) OVER (ORDER BY monetary DESC) AS rev_decile
    FROM customer_rev
)
SELECT
    CASE WHEN rev_decile = 1 THEN 'Top 10%' ELSE 'Bottom 90%' END AS band,
    COUNT(*)                                                       AS customers,
    CAST(SUM(monetary) AS DECIMAL(14,2))                          AS revenue,
    CAST(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER () AS DECIMAL(5,2)) AS revenue_share_pct
FROM decile
GROUP BY CASE WHEN rev_decile = 1 THEN 'Top 10%' ELSE 'Bottom 90%' END
ORDER BY revenue DESC;
