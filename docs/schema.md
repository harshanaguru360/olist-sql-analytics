# Data model

The nine raw Olist tables are normalized for transactions, not analysis. This
project collapses them into a star schema with two fact grains and five
dimensions, which is what makes the analytical queries short and fast.

## Source tables (staging)

The Olist release ships several CSVs. They land in the `staging` schema exactly
as they arrive, every column text, no constraints. Typing and validation happen
on the way into the star schema.

| File | Grain | Notes |
|------|-------|-------|
| olist_customers_dataset | one row per order's customer | `customer_unique_id` is the real person; `customer_id` is per order |
| olist_orders_dataset | one row per order | status plus four lifecycle timestamps |
| olist_order_items_dataset | one row per order line | price and freight live here |
| olist_order_payments_dataset | one row per payment | an order can have several |
| olist_order_reviews_dataset | one row per review | score 1 to 5 |
| olist_products_dataset | one row per product | category in Portuguese |
| olist_sellers_dataset | one row per seller | |
| product_category_name_translation | category lookup | Portuguese to English |

A subtlety worth knowing for interviews: `customer_id` in the orders table is
unique per order, so counting it overstates customers. `customer_unique_id` is
the stable identity, which is why every repeat-purchase and RFM query groups on
it.

## Star schema

Two fact tables because the questions live at two grains.

```
                 dim_date
                    |
   dim_customer --- fact_orders --- (payment, review, delivery measures)
                    |
                    |  order_key
                    |
              fact_order_items --- dim_product
                    |
                 dim_seller
                    |
              dim_geography (by zip prefix)
```

### fact_orders (one row per order)

Carries the order-level measures, several of them pre-computed in the load so
the analysis stays readable:

- `delivery_days` purchase to actual customer delivery
- `estimated_days` purchase to the promised date
- `delay_days` actual minus promised, positive means late
- `is_late` flag derived from `delay_days`
- `payment_type`, `payment_installments`, `payment_value` folded from payments
- `review_score` first review per order
- `order_value`, `item_count`

### fact_order_items (one row per order line)

Needed because a single order can span several sellers and products. Seller GMV
(q6) and product economics can only be measured at this grain.

### Dimensions

`dim_date` (a real calendar table), `dim_customer`, `dim_seller`, `dim_product`
(category translated to English on load), and `dim_geography` (one row per zip
prefix, built from the locations that appear on customers and sellers).
