/* ===========================================================================
   Q6. Seller concentration: how much GMV runs through the top sellers?

   GMV here is item price plus freight. We rank sellers by GMV and use a running
   cumulative share to find where the top decile of sellers lands. A marketplace
   where a thin band of sellers carries most of GMV has a concentration risk
   worth naming.
   =========================================================================== */

WITH seller_gmv AS (
    SELECT
        s.seller_id,
        s.state AS seller_state,
        SUM(fi.price + COALESCE(fi.freight_value, 0)) AS gmv
    FROM star.fact_order_items fi
    JOIN star.dim_seller s ON s.seller_key = fi.seller_key
    GROUP BY s.seller_id, s.state
),
ranked AS (
    SELECT
        seller_id,
        seller_state,
        gmv,
        ROW_NUMBER() OVER (ORDER BY gmv DESC)                          AS gmv_rank,
        COUNT(*)    OVER ()                                            AS total_sellers,
        SUM(gmv)    OVER (ORDER BY gmv DESC
                          ROWS UNBOUNDED PRECEDING)                    AS running_gmv,
        SUM(gmv)    OVER ()                                            AS total_gmv
    FROM seller_gmv
)
SELECT
    gmv_rank,
    seller_state,
    CAST(gmv AS DECIMAL(12,2))                                       AS seller_gmv,
    CAST(100.0 * running_gmv / total_gmv AS DECIMAL(5,2))           AS cumulative_gmv_share_pct,
    CAST(100.0 * gmv_rank / total_sellers AS DECIMAL(5,2))          AS seller_percentile
FROM ranked
WHERE gmv_rank <= total_sellers / 10        -- the top decile of sellers
ORDER BY gmv_rank;
