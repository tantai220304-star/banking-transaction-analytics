
-- ============================================================
-- BANKING TRANSACTION ANALYTICS
-- AMOUNT PRECISION CORRECTION
-- ============================================================
-- Objective: Preserve the original transaction amounts
-- during the SSIS ETL process.
--
-- Issue: A Bitcoin transaction amount of 0.003327
-- was stored as 0.00 due to insufficient decimal scale.
--
-- Solution: Increase decimal precision and scale.
-- ============================================================

USE BankingAnalytics;
GO

-- Update transaction amount data types
ALTER TABLE dbo.Transactions
ALTER COLUMN AmountPaid DECIMAL(28,8) NULL;

ALTER TABLE dbo.Transactions
ALTER COLUMN AmountReceived DECIMAL(28,8) NULL;

-- Verify updated column properties
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Transactions'
  AND COLUMN_NAME IN ('AmountPaid', 'AmountReceived');

-- Check column AmountPaid and AmountReceived
SELECT
    TransactionID,
    AmountPaid,
    AmountReceived,
    PaymentCurrency,
    PaymentFormat
FROM dbo.Transactions
WHERE TransactionID = 58474;