/* ===========================================================================
   01_bulk_insert_staging.sql
   Loads the nine raw CSVs into the staging schema.

   This is the one engine-specific step in the project. BULK INSERT is SQL
   Server's native loader; the rest of the SQL is portable. FORMAT = 'CSV'
   (SQL Server 2017 and later) handles quoted fields and embedded commas, so
   review text with commas in it loads correctly.

   BEFORE RUNNING:
     1. Set @data below to the absolute path of your data/raw folder.
     2. The SQL Server service account must be able to read that folder. If you
        hit "Operating system error 5 (Access is denied)", copy data/raw to a
        path the service can read (for example C:\OlistData\) and point @data
        there, or grant the service account read access on the folder.

   Re-running is safe: each table is truncated before load.
   =========================================================================== */

USE OlistAnalytics;
GO

-- Edit this one line to match your machine, keep the trailing backslash.
DECLARE @data NVARCHAR(260) = N'C:\Users\harsh\portfolio\03-olist-sql-analytics\data\raw\';
DECLARE @sql  NVARCHAR(MAX);

/* Helper pattern: truncate then bulk load each file. Dynamic SQL is used only
   so the folder path can be supplied once as a variable. */

TRUNCATE TABLE staging.customers;
SET @sql = N'BULK INSERT staging.customers FROM ''' + @data + N'olist_customers_dataset.csv''
            WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', TABLOCK);';
EXEC sp_executesql @sql;

TRUNCATE TABLE staging.sellers;
SET @sql = N'BULK INSERT staging.sellers FROM ''' + @data + N'olist_sellers_dataset.csv''
            WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', TABLOCK);';
EXEC sp_executesql @sql;

TRUNCATE TABLE staging.products;
SET @sql = N'BULK INSERT staging.products FROM ''' + @data + N'olist_products_dataset.csv''
            WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', TABLOCK);';
EXEC sp_executesql @sql;

TRUNCATE TABLE staging.category_translation;
SET @sql = N'BULK INSERT staging.category_translation FROM ''' + @data + N'product_category_name_translation.csv''
            WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', TABLOCK);';
EXEC sp_executesql @sql;

TRUNCATE TABLE staging.orders;
SET @sql = N'BULK INSERT staging.orders FROM ''' + @data + N'olist_orders_dataset.csv''
            WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', TABLOCK);';
EXEC sp_executesql @sql;

TRUNCATE TABLE staging.order_items;
SET @sql = N'BULK INSERT staging.order_items FROM ''' + @data + N'olist_order_items_dataset.csv''
            WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', TABLOCK);';
EXEC sp_executesql @sql;

TRUNCATE TABLE staging.order_payments;
SET @sql = N'BULK INSERT staging.order_payments FROM ''' + @data + N'olist_order_payments_dataset.csv''
            WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', TABLOCK);';
EXEC sp_executesql @sql;

TRUNCATE TABLE staging.order_reviews;
SET @sql = N'BULK INSERT staging.order_reviews FROM ''' + @data + N'olist_order_reviews_dataset.csv''
            WITH (FORMAT=''CSV'', FIRSTROW=2, FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'', TABLOCK);';
EXEC sp_executesql @sql;
GO

/* Sanity check: row counts after load */
SELECT 'customers' AS table_name, COUNT(*) AS rows FROM staging.customers
UNION ALL SELECT 'sellers',        COUNT(*) FROM staging.sellers
UNION ALL SELECT 'products',       COUNT(*) FROM staging.products
UNION ALL SELECT 'category_xlat',  COUNT(*) FROM staging.category_translation
UNION ALL SELECT 'orders',         COUNT(*) FROM staging.orders
UNION ALL SELECT 'order_items',    COUNT(*) FROM staging.order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM staging.order_payments
UNION ALL SELECT 'order_reviews',  COUNT(*) FROM staging.order_reviews;
GO
