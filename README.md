# Olist E-commerce SQL Analytics

I took the Brazilian Olist e-commerce dataset, around 100k real orders spread
across nine related tables, modeled it into a star schema on SQL Server, and
answered eight business questions in SQL: RFM segmentation, cohort retention,
delivery economics, seller concentration, and the link between late delivery and
review scores.

The whole thing runs from raw CSV to final result. I built it and validated it on
SQL Server 2025.

## Why I chose this dataset

Olist is Brazil's largest department store marketplace, and it published this
dataset covering roughly 100k orders from 2016 to 2018 across nine normalized
tables (customers, orders, order items, payments, reviews, products, sellers, and
a category translation). I picked it because, unlike a single flat CSV, it forces
real joins and real modeling decisions, which is what I wanted to practice and be
able to defend.

## What I built

- **A star schema** from nine transactional tables: two fact grains
  (`fact_orders` at order level, `fact_order_items` at line level) and five
  dimensions. I wrote up the model and the reasoning in
  [docs/schema.md](docs/schema.md).
- **A defensive load.** Raw data lands as text in a staging schema first, then I
  type it with `TRY_CAST` and `NULLIF` on the way into the model, so one bad
  value never aborts a load.
- **Eight analytical queries** in `sql/04-business-questions/`, each answering a
  stated question with window functions (`NTILE` for RFM quintiles and revenue
  deciles, `ROW_NUMBER`, running totals), CTEs, and a recursive calendar
  dimension.

I kept the analytical SQL in standard form (CTEs, standard window functions,
`OFFSET ... FETCH` rather than `TOP`) so it transfers to other engines. The only
engine-specific piece is the load, where I use SQL Server's `BULK INSERT`.

## The eight questions, and what I found

The full write-up with numbers is in [docs/findings.md](docs/findings.md). In
short:

1. **Repeat purchase by category.** Olist is mostly single-purchase; repeat
   buying concentrates in consumables (diapers/hygiene ~26%, appliances ~18%).
2. **Delivery delays by geography.** The worst lanes are long hauls into the
   remote north (Alagoas, Maranhao), up to ~39% late.
3. **Review lift from on-time delivery.** On-time orders score about two to two
   and a half stars higher than late ones, across nearly every category.
4. **Installments, basket size, dissatisfaction.** The one-star rate rises with
   order value and installment count.
5. **RFM and revenue concentration.** The top 10% of customers drive ~38.5% of
   revenue.
6. **Seller concentration.** The top 10% of sellers carry ~67% of GMV, mostly in
   Sao Paulo.
7. **Cohort retention.** Under 2% inside the first year, expected for a
   single-purchase marketplace.
8. **Lifecycle and SLA.** Olist beats its own delivery promise on average; when
   orders are late, the carrier leg is where the time goes.

## Repo layout

```
03-olist-sql-analytics/
├── data/
│   └── raw/                       # the Olist CSVs (included in the repo)
├── sql/
│   ├── 01-ddl/                    # database, staging tables, star schema
│   ├── 02-staging-loads/          # BULK INSERT of the CSVs
│   ├── 03-dim-fact/               # staging into dimensions and facts
│   └── 04-business-questions/     # one file per question
├── docs/
│   ├── schema.md                  # the data model and why
│   └── findings.md                # the results, with numbers
└── README.md
```

## Running it yourself

1. In `sql/02-staging-loads/01_bulk_insert_staging.sql`, set the `@data` path to
   this repo's `data/raw` folder.
2. Run the scripts in order in SSMS or with `sqlcmd`:
   ```
   sqlcmd -S "localhost\SQLEXPRESS" -E -C            -i sql/01-ddl/01_create_database.sql
   sqlcmd -S "localhost\SQLEXPRESS" -E -C -d OlistAnalytics -i sql/01-ddl/02_create_staging_tables.sql
   sqlcmd -S "localhost\SQLEXPRESS" -E -C -d OlistAnalytics -i sql/01-ddl/03_create_star_schema.sql
   sqlcmd -S "localhost\SQLEXPRESS" -E -C -d OlistAnalytics -i sql/02-staging-loads/01_bulk_insert_staging.sql
   sqlcmd -S "localhost\SQLEXPRESS" -E -C -d OlistAnalytics -i sql/03-dim-fact/01_load_dimensions.sql
   sqlcmd -S "localhost\SQLEXPRESS" -E -C -d OlistAnalytics -i sql/03-dim-fact/02_load_facts.sql
   ```
3. Run any file in `sql/04-business-questions/`.

## Data source

Brazilian E-Commerce Public Dataset by Olist, published on Kaggle
(kaggle.com/datasets/olistbr/brazilian-ecommerce) under CC BY-NC-SA 4.0. The data
is included here for reproducibility, with attribution to Olist.

Built by Naguru Sai Harsha Vardhan.
