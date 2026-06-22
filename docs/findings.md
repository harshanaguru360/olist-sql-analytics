# Findings

These are the results I get on the real Olist dataset (about 100k orders placed
between 2016 and 2018). Each section is the business question, what I did, and
what the data actually showed. Numbers come straight from the queries in
`sql/04-business-questions/`.

## Q1. Repeat purchase by category

Olist is overwhelmingly a single-purchase marketplace, so repeat rates are low
across the board, which is itself the finding. Where repeat buying does show up,
it is in consumable and replenishment categories: diapers and hygiene leads at
about 26%, home appliances at 18%, and bed/bath/table, the highest-volume
category at over 11k items, sits around 10%. If I were advising Olist on where a
loyalty program could pay off, I would start with the consumables, not the
one-off purchases.

## Q2. Where delivery delays cluster

The worst lanes are the long hauls into the remote north and northeast.
Deliveries to Alagoas from Paraná sellers run about 39% late, and the
Maranhao-from-Sao-Paulo lane is late on roughly 21% of 493 orders, often by
8 to 13 days. The pattern is distance: sellers concentrated in the southeast
shipping to far states. This is the query that tells an operations team which
routes to renegotiate first.

## Q3. Review lift from on-time delivery

This is the strongest result in the project. Across almost every category,
orders delivered on time score roughly two to two and a half stars higher than
late ones (on-time averages near 4.3, late ones near 2.0). The takeaway I draw
is that a large share of what looks like product dissatisfaction is actually
logistics. Controlling by category rules out a category-mix explanation.

## Q4. Installments, basket size, and dissatisfaction

The one-star rate climbs with both order value and installment count. Small
single-payment baskets sit around 9%, while larger orders spread over more
installments push past 11 to 12%. It is a mild but consistent gradient, the kind
of thing worth watching in a market where installment payment is the default.

## Q5. RFM segmentation and revenue concentration

I scored every customer on recency, frequency, and monetary value with `NTILE`
quintiles and rolled them into named segments. The concentration query gives the
headline directly: the top 10% of customers by spend drive about 38.5% of total
revenue, the other 90% the remaining 61.5%. Real but not extreme concentration,
consistent with a marketplace where most people buy once.

## Q6. Seller concentration

GMV is far more concentrated on the supply side. The top 10% of sellers (about
310 of 3,095) carry roughly 67% of all GMV, and the very top sellers are almost
all in Sao Paulo. That is a real key-account and marketplace-health risk: lose a
handful of sellers and a large slice of GMV goes with them.

## Q7. Cohort retention

Grouping customers by first-purchase month, return rates inside the first year
sit well under 2%. That sounds alarming until you remember Olist is a
single-purchase marketplace, so the absolute level is expected. What I would
watch is the shape across cohorts rather than the level.

## Q8. Lifecycle and SLA

Olist actually beats its own promise: orders take about 12.5 days on average
against a promised 24.4, and only about 8% arrive late. Splitting the legs, the
carrier stretch dominates the timeline (around 223 hours) versus seller handoff
(67 hours) and payment approval (10 hours). So when an order is late, the place
to look is the carrier, not the seller or the payment step.

## Honest caveats

- I pulled the data from a public mirror of the Olist dataset and verified it by
  row count against the known totals. The canonical source is Kaggle
  (kaggle.com/datasets/olistbr/brazilian-ecommerce); fetching it there is the way
  to be fully certain of integrity.
- `dim_geography` is built from the zip prefixes that appear on customers and
  sellers, not from a separate lat/long feed, so it carries location names but
  not coordinates.
- Reviews free-text fields were stripped of embedded line breaks on load; the
  analysis only uses the score and dates, so this does not affect any result.
