/* ===========================================================================
   01_create_database.sql
   Creates the OlistAnalytics database and two schemas:
     staging  : raw CSV landing zone, every column text, no constraints
     star     : the modeled dimensions and facts the analysis runs against
   Run this first, in SSMS, against your local SQL Server 2025 instance.
   =========================================================================== */

IF DB_ID('OlistAnalytics') IS NULL
    CREATE DATABASE OlistAnalytics;
GO

USE OlistAnalytics;
GO

IF SCHEMA_ID('staging') IS NULL
    EXEC('CREATE SCHEMA staging');
GO

IF SCHEMA_ID('star') IS NULL
    EXEC('CREATE SCHEMA star');
GO
