-- ============================================================
-- BANKING TRANSACTION ANALYTICS
-- RECORD-LEVEL RECONCILIATION
-- ============================================================
-- Objective: Identify completely duplicated transactions
-- in SQL Server before performing record-level comparison.

USE BankingAnalytics;
GO

-- 1. CHECK DUPLICATE RECORDS
WITH DuplicateCheck AS (
    SELECT
        TransactionTimestamp,
        FromBank,
        FromAccount,
        ToBank,
        ToAccount,
        AmountReceived,
        ReceivingCurrency,
        AmountPaid,
        PaymentCurrency,
        PaymentFormat,
        IsLaundering,
        COUNT(*) AS Occurrences
    FROM dbo.Transactions
    GROUP BY
        TransactionTimestamp,
        FromBank,
        FromAccount,
        ToBank,
        ToAccount,
        AmountReceived,
        ReceivingCurrency,
        AmountPaid,
        PaymentCurrency,
        PaymentFormat,
        IsLaundering
)
SELECT
    COUNT(*) AS UniqueRecordGroups,
    SUM(Occurrences) AS TotalRecords,
    SUM(Occurrences - 1) AS DuplicateRecords
FROM DuplicateCheck;


-- ============================================================
-- 2. CREATE SOURCE STAGING TABLE
-- ============================================================
-- Objective: Create a separate table for comparing
-- processed CSV records with the destination table.

SELECT TOP (0)
    TransactionTimestamp,
    FromBank,
    FromAccount,
    ToBank,
    ToAccount,
    AmountReceived,
    ReceivingCurrency,
    AmountPaid,
    PaymentCurrency,
    PaymentFormat,
    IsLaundering
INTO dbo.Transactions_Staging
FROM dbo.Transactions;

-- Verify the staging table is empty
SELECT COUNT(*) AS StagingRecords
FROM dbo.Transactions_Staging;

SELECT TOP (5) *
FROM dbo.Transactions_Staging;


-- ============================================================
-- 4. RECORD-LEVEL COMPARISON
-- ============================================================
-- Objective: Identify transactions present in the main
-- table but missing from the staging table.

SELECT
    TransactionTimestamp,
    FromBank,
    FromAccount,
    ToBank,
    ToAccount,
    AmountReceived,
    ReceivingCurrency,
    AmountPaid,
    PaymentCurrency,
    PaymentFormat,
    IsLaundering
FROM dbo.Transactions

EXCEPT

SELECT
    TransactionTimestamp,
    FromBank,
    FromAccount,
    ToBank,
    ToAccount,
    AmountReceived,
    ReceivingCurrency,
    AmountPaid,
    PaymentCurrency,
    PaymentFormat,
    IsLaundering
FROM dbo.Transactions_Staging;

SELECT
    TransactionTimestamp,
    FromBank,
    FromAccount,
    ToBank,
    ToAccount,
    AmountReceived,
    ReceivingCurrency,
    AmountPaid,
    PaymentCurrency,
    PaymentFormat,
    IsLaundering
FROM dbo.Transactions_Staging

EXCEPT

SELECT
    TransactionTimestamp,
    FromBank,
    FromAccount,
    ToBank,
    ToAccount,
    AmountReceived,
    ReceivingCurrency,
    AmountPaid,
    PaymentCurrency,
    PaymentFormat,
    IsLaundering
FROM dbo.Transactions;


-- ============================================================
-- 6. STAGING DUPLICATE VALIDATION
-- ============================================================
-- Objective: Check whether the staging table contains
-- fully duplicated transaction records.

WITH StagingDuplicateCheck AS (
    SELECT
        TransactionTimestamp,
        FromBank,
        FromAccount,
        ToBank,
        ToAccount,
        AmountReceived,
        ReceivingCurrency,
        AmountPaid,
        PaymentCurrency,
        PaymentFormat,
        IsLaundering,
        COUNT(*) AS Occurrences
    FROM dbo.Transactions_Staging
    GROUP BY
        TransactionTimestamp,
        FromBank,
        FromAccount,
        ToBank,
        ToAccount,
        AmountReceived,
        ReceivingCurrency,
        AmountPaid,
        PaymentCurrency,
        PaymentFormat,
        IsLaundering
)
SELECT
    COUNT(*) AS UniqueRecordGroups,
    SUM(Occurrences) AS TotalRecords,
    SUM(Occurrences - 1) AS DuplicateRecords
FROM StagingDuplicateCheck;
