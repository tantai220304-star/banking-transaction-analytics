-- 1.0 Create a database
CREATE DATABASE BankingAnalytics;

-- 1.1 Switch to the banking analytics database
Use BankingAnalytics;

-- 2.0 Create Banking Transactions Table
-- Objective: Store banking transaction records
-- Source: IBM Synthetic Financial Transactions Dataset 
CREATE TABLE dbo.Transactions (
    TransactionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    TransactionTimestamp DATETIME2(0),
    FromBank VARCHAR(20),
    FromAccount VARCHAR(50),
    ToBank VARCHAR(20),
    ToAccount VARCHAR(50),
    AmountReceived DECIMAL(20,2),
    ReceivingCurrency VARCHAR(30),
    AmountPaid DECIMAL(20,2),
    PaymentCurrency VARCHAR(30),
    PaymentFormat VARCHAR(30),
    IsLaundering BIT
);

-- 2.1 Verify the table structure
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH, -- Varchar maximum
    NUMERIC_PRECISION, -- Total number of digits for numeric columns
    NUMERIC_SCALE      -- Number of digits after the decimal point
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' 
AND TABLE_NAME = 'Transactions'
ORDER BY ORDINAL_POSITION;

-- 3.0 Verify the target table before importing data
-- Objective: Ensure the table is empty to avoid duplicate imports.

SELECT COUNT(*) AS TotalRecords
FROM dbo.Transactions;


-- ============================================================
-- 3.0 PRE-IMPORT VALIDATION
-- ============================================================
-- Objective: Verify that the destination table is empty
-- before running the SSIS ETL package.

SELECT COUNT(*) AS TotalRecords
FROM dbo.Transactions;


-- ============================================================
-- 3.1 DATA IMPORT USING SSIS
-- ============================================================
-- ETL Tool: SQL Server Integration Services (SSIS)
-- Package: 01_Load_Banking_Transactions.dtsx
-- Source: banking_transactions_100k.csv
-- Destination: BankingAnalytics.dbo.Transactions
--
-- ETL Workflow:
-- 1. Extract transaction records from the CSV file.
-- 2. Convert data types to match the SQL Server schema.
-- 3. Load the prepared records into dbo.Transactions.
--
-- Note: Data import is executed through SSIS in Visual Studio,
-- not directly through this SQL script.



