
-- ============================================================
-- BANKING TRANSACTION ANALYTICS
-- POST-IMPORT DATA VALIDATION
-- ============================================================
-- Objective: Validate transaction data imported through SSIS.
-- Source: banking_transactions_100k.csv
-- Destination: BankingAnalytics.dbo.Transactions
-- ETL Tool: SQL Server Integration Services (SSIS)
-- ============================================================

USE BankingAnalytics;
GO

-- 1. Record Count Validation
-- 2. Timestamp Validation
-- 3. Missing Values Validation
-- 4. Transaction Amount Validation
-- 5. Zero-Amount Investigation
-- 6. Source-to-Destination Reconciliation




-- ============================================================
-- 1. RECORD COUNT VALIDATION
-- ============================================================
-- Objective: Verify that all expected transaction records
-- were successfully imported into SQL Server.

SELECT
    COUNT(*) AS TotalRecords
FROM dbo.Transactions;


-- ============================================================
-- 2. TIMESTAMP VALIDATION
-- ============================================================
-- Objective: Verify the transaction date range after ETL.

SELECT
    MIN(TransactionTimestamp) AS EarliestTransaction,
    MAX(TransactionTimestamp) AS LatestTransaction
FROM dbo.Transactions;


-- ============================================================
-- 3. MISSING VALUES VALIDATION
-- ============================================================
-- Objective: Identify missing values in critical columns
-- after the SSIS ETL process.

SELECT
    SUM(CASE WHEN TransactionTimestamp IS NULL THEN 1 ELSE 0 END)
        AS MissingTimestamps,
    SUM(CASE WHEN AmountPaid IS NULL THEN 1 ELSE 0 END)
        AS MissingAmountPaid,
    SUM(CASE WHEN AmountReceived IS NULL THEN 1 ELSE 0 END)
        AS MissingAmountReceived,
    SUM(CASE WHEN IsLaundering IS NULL THEN 1 ELSE 0 END)
        AS MissingLaunderingLabels
FROM dbo.Transactions;



-- ============================================================
-- 4. TRANSACTION AMOUNT VALIDATION
-- ============================================================
-- Objective: Validate transaction amount ranges and
-- identify negative or zero-value transactions.

SELECT
    MIN(AmountPaid) AS MinAmountPaid,
    MAX(AmountPaid) AS MaxAmountPaid,
    MIN(AmountReceived) AS MinAmountReceived,
    MAX(AmountReceived) AS MaxAmountReceived,

    SUM(CASE WHEN AmountPaid < 0 THEN 1 ELSE 0 END)
        AS NegativeAmountPaid,
    SUM(CASE WHEN AmountReceived < 0 THEN 1 ELSE 0 END)
        AS NegativeAmountReceived,

    SUM(CASE WHEN AmountPaid = 0 THEN 1 ELSE 0 END)
        AS ZeroAmountPaid,
    SUM(CASE WHEN AmountReceived = 0 THEN 1 ELSE 0 END)
        AS ZeroAmountReceived
FROM dbo.Transactions;



-- ============================================================
-- 5. ZERO-AMOUNT INVESTIGATION
-- ============================================================
-- Objective: Investigate zero-value transactions and
-- identify their payment formats and currencies.

-- Review zero-amount transaction records
SELECT TOP (20)
    TransactionID,
    TransactionTimestamp,
    AmountPaid,
    PaymentCurrency,
    AmountReceived,
    ReceivingCurrency,
    PaymentFormat,
    IsLaundering
FROM dbo.Transactions
WHERE AmountPaid = 0
   OR AmountReceived = 0
ORDER BY TransactionID;

-- Which payment formats and currencies contain zero-value transactions?
SELECT
    PaymentFormat,
    PaymentCurrency,
    COUNT(*) AS ZeroAmountTransactions
FROM dbo.Transactions
WHERE AmountPaid = 0
   OR AmountReceived = 0
GROUP BY
    PaymentFormat,
    PaymentCurrency
ORDER BY ZeroAmountTransactions DESC;



-- ============================================================
-- 6. SOURCE-TO-DESTINATION RECONCILIATION
-- ============================================================
-- Objective: Prepare destination-side validation metrics
-- for comparison with the source CSV.
--
-- Note: Full reconciliation requires source-side metrics
-- from the original CSV file.

SELECT
    COUNT(*) AS TotalTransactions,

    MIN(TransactionTimestamp) AS EarliestTransaction,
    MAX(TransactionTimestamp) AS LatestTransaction,

    MIN(AmountPaid) AS MinAmountPaid,
    MAX(AmountPaid) AS MaxAmountPaid,

    MIN(AmountReceived) AS MinAmountReceived,
    MAX(AmountReceived) AS MaxAmountReceived,

    SUM(CASE WHEN IsLaundering = 1 THEN 1 ELSE 0 END)
        AS LabelledTransactions

FROM dbo.Transactions;



-- ============================================================
-- 7. FINAL ETL VALIDATION
-- ============================================================
-- Objective: Verify record count and amount precision
-- after correcting the ETL pipeline.

SELECT
    COUNT(*) AS TotalRecords,
    MIN(AmountPaid) AS MinAmountPaid,
    MIN(AmountReceived) AS MinAmountReceived,
    SUM(CASE WHEN AmountPaid = 0 THEN 1 ELSE 0 END)
        AS ZeroAmountPaid,
    SUM(CASE WHEN AmountReceived = 0 THEN 1 ELSE 0 END)
        AS ZeroAmountReceived
FROM dbo.Transactions;

-- Verify the updated decimal schema
SELECT
    COLUMN_NAME,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Transactions'
  AND COLUMN_NAME IN ('AmountPaid', 'AmountReceived');


-- ============================================================
-- FINAL ETL VALIDATION FINDINGS
-- ============================================================
-- 1. Successfully loaded 100,000 transaction records.
-- 2. No zero or negative transaction amounts were detected.
-- 3. Transaction amount columns use DECIMAL(28,8).
-- 4. The previously affected Bitcoin transaction now
--    preserves its original value of 0.003327.
-- 5. Initial post-import validation checks passed.
-- 6. Full source-to-destination reconciliation remains
--    necessary to confirm record-level data accuracy.



-- ============================================================
-- 8. SOURCE-TO-DESTINATION RECONCILIATION
-- ============================================================
-- Objective: Generate destination metrics to compare
-- against the processed CSV source.

SELECT
    COUNT(*) AS TotalTransactions,
    SUM(AmountPaid) AS TotalAmountPaid,
    SUM(AmountReceived) AS TotalAmountReceived,
    MIN(AmountPaid) AS MinAmountPaid,
    MAX(AmountPaid) AS MaxAmountPaid,
    MIN(AmountReceived) AS MinAmountReceived,
    MAX(AmountReceived) AS MaxAmountReceived,
    SUM(CASE WHEN IsLaundering = 1 THEN 1 ELSE 0 END)
        AS LaunderingTransactions
FROM dbo.Transactions;



-- ============================================================
-- 9. CURRENCY-LEVEL RECONCILIATION
-- ============================================================
-- Objective: Validate transaction counts and monetary
-- totals within each currency.

SELECT
    PaymentCurrency,
    COUNT(*) AS TransactionCount,
    SUM(AmountPaid) AS TotalAmountPaid
FROM dbo.Transactions
GROUP BY PaymentCurrency
ORDER BY PaymentCurrency;











