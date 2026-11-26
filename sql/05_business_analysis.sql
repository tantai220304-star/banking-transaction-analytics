
-- ============================================================
-- BANKING TRANSACTION ANALYTICS
-- SQL BUSINESS ANALYSIS
-- ============================================================
-- Objective:
-- Analyze banking transactions to identify transaction
-- patterns, payment behaviors, and potential risk indicators.
--
-- Dataset:
-- IBM Synthetic Financial Transactions Dataset
-- First 100,000 transaction records
--
-- Database:
-- BankingAnalytics
-- ============================================================

USE BankingAnalytics;
GO



-- ============================================================
-- 1. TRANSACTION OVERVIEW
-- ============================================================
-- Business Question:
-- How many transactions were processed, and what was
-- the average,minimum,and maximum transaction amount?
-- ============================================================

SELECT
    COUNT(*) AS TotalTransactions,
    AVG(AmountPaid) AS AvgAmountPaid,
    MIN(AmountPaid) AS MinAmountPaid,
    MAX(AmountPaid) AS MaxAmountPaid
FROM dbo.Transactions;


-- Finding:
-- The dataset contains 100,000 transactions, with an
-- average recorded AmountPaid of approximately 756,340.82.
-- Transaction amounts range from 0.003327 to 5.35 billion.
-- Since multiple currencies are present, these aggregate
-- amounts should not be interpreted as USD values.



-- ============================================================
-- 2. TRANSACTION OVERVIEW BY CURRENCY
-- ============================================================
-- Business Question:
-- What are the transaction counts and average payment
-- amounts for each currency?
-- ============================================================

SELECT
    PaymentCurrency,
    COUNT(*) AS TotalTransactions,
    AVG(AmountPaid) AS AvgAmountPaid,
    MIN(AmountPaid) AS MinAmountPaid,
    MAX(AmountPaid) AS MaxAmountPaid
FROM dbo.Transactions
GROUP BY PaymentCurrency
ORDER BY TotalTransactions DESC;


-- Findings:
-- 1. US Dollar transactions account for approximately
--    99.63% of the 100,000-record sample.
-- 2. Transaction amounts vary significantly within
--    individual currencies.
-- 3. Currency-specific averages should not be compared
--    directly without exchange-rate conversion.
-- 4. Median analysis is recommended because large
--    transactions may influence the averages.



-- ============================================================
-- 3. AVERAGE VS MEDIAN TRANSACTION AMOUNT
-- ============================================================
-- Business Question:
-- How does the median transaction amount compare with
-- the average amount for each payment currency?
-- ============================================================

WITH CurrencyMedian AS (
    SELECT
        PaymentCurrency,
        AmountPaid,
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY AmountPaid
        ) OVER (
            PARTITION BY PaymentCurrency
        ) AS MedianAmountPaid
    FROM dbo.Transactions--;
)

SELECT
    PaymentCurrency,
    COUNT(*) AS TotalTransactions,
    AVG(AmountPaid) AS AvgAmountPaid,
    MAX(MedianAmountPaid) AS MedianAmountPaid
FROM CurrencyMedian
GROUP BY PaymentCurrency
ORDER BY TotalTransactions DESC;


-- Findings:
-- 1. Average transaction amounts are substantially higher
--    than median amounts across most payment currencies.
-- 2. For US Dollar transactions, the average AmountPaid
--    is approximately 363 times the median.
-- 3. This suggests a strongly right-skewed distribution,
--    where large transactions influence the average.
-- 4. The median provides a more representative measure
--    of a typical transaction amount in this sample.
--
-- Recommendation:
-- Investigate transaction amount distributions and
-- potential outliers before drawing conclusions about
-- unusual transaction behavior.



-- ============================================================
-- 4. TRANSACTION COUNT BY PAYMENT FORMAT
-- ============================================================
-- Business Question:
-- Which payment formats are most frequently used
-- in the transaction dataset?
-- ============================================================

SELECT
    PaymentFormat,
    COUNT(*) AS TotalTransactions
FROM dbo.Transactions
GROUP BY PaymentFormat
ORDER BY TotalTransactions DESC;


-- Findings:
-- 1. Reinvestment is the most frequent payment format,
--    accounting for 73.30% of all transactions.
-- 2. Cheque and Credit Card have similar transaction
--    counts, representing 9.39% and 9.03%, respectively.
-- 3. Bitcoin is the least frequent payment format,
--    accounting for only 0.03% of transactions.
--
-- Limitation:
-- These findings are based on the first 100,000 records
-- and may not represent the full dataset.



-- ============================================================
-- 5. PAYMENT FORMAT PERCENTAGE
-- ============================================================
-- Business Question:
-- What percentage of total transactions does each
-- payment format represent?
-- ============================================================

SELECT
    PaymentFormat,
    COUNT(*) AS TotalTransactions,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS TransactionPercentage
FROM dbo.Transactions
GROUP BY PaymentFormat
ORDER BY TotalTransactions DESC;


-- Findings:
-- 1. Reinvestment accounts for 73.30% of transactions,
--    indicating a highly concentrated payment distribution.
-- 2. Cheque and Credit Card together represent 18.42%
--    of the transaction sample.
-- 3. Bitcoin represents only 0.03% of transactions.
--
-- Limitation:
-- The percentages describe transaction frequency,
-- not the monetary value transferred.



-- ============================================================
-- 6. PAYMENT AMOUNT ANALYSIS (USD)
-- ============================================================
-- Business Question:
-- How do transaction amounts differ across payment
-- formats for US Dollar transactions?
-- ============================================================

SELECT
    PaymentFormat,
    COUNT(*) AS TotalTransactions,
    SUM(AmountPaid) AS TotalAmountPaid,
    AVG(AmountPaid) AS AvgAmountPaid,
    MIN(AmountPaid) AS MinAmountPaid,
    MAX(AmountPaid) AS MaxAmountPaid
FROM dbo.Transactions
WHERE PaymentCurrency = 'US Dollar'
GROUP BY PaymentFormat
ORDER BY TotalAmountPaid DESC;


-- Findings:
-- 1. Reinvestment has the highest transaction count
--    among USD transactions (73,241 records).
-- 2. Cheque has the highest total AmountPaid,
--    approximately $30.57 billion USD.
-- 3. Cash has the highest average AmountPaid,
--    approximately $4.05 million USD.
-- 4. Transaction frequency does not necessarily
--    correspond to total monetary value.
--
-- Limitation:
-- Large transactions may significantly influence
-- the average amounts and total values.



-- ============================================================
-- 7. AVERAGE VS MEDIAN BY PAYMENT FORMAT (USD)
-- ============================================================
-- Business Question:
-- Which USD payment formats show the largest differences
-- between average and median transaction amounts?
-- ============================================================

WITH PaymentMedian AS (
    SELECT
        PaymentFormat,
        AmountPaid,
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY AmountPaid
        ) OVER (
            PARTITION BY PaymentFormat
        ) AS MedianAmountPaid
    FROM dbo.Transactions
    WHERE PaymentCurrency = 'US Dollar'
)

SELECT
    PaymentFormat,
    COUNT(*) AS TotalTransactions,
    AVG(AmountPaid) AS AvgAmountPaid,
    CAST(MAX(MedianAmountPaid) AS DECIMAL(28,8))
        AS MedianAmountPaid
FROM PaymentMedian
GROUP BY PaymentFormat
ORDER BY TotalTransactions DESC;


-- Findings:
-- 1. Average transaction amounts are substantially higher
--    than median amounts across most USD payment formats.
-- 2. ACH has the largest average-to-median ratio,
--    approximately 436 times.
-- 3. Cash has the highest average and median AmountPaid
--    among the USD payment formats.
-- 4. These differences suggest right-skewed transaction
--    amount distributions.
--
-- Limitation:
-- Large transaction amounts are not necessarily anomalies
-- or evidence of money laundering.
-- The Bitcoin payment format has only one USD record.



-- ============================================================
-- 8. TOP 10 SENDING BANKS
-- ============================================================
-- Business Question:
-- Which banks have the highest number of
-- outgoing transactions?
-- ============================================================

SELECT TOP (10)
    FromBank,
    COUNT(*) AS OutgoingTransactions
FROM dbo.Transactions
GROUP BY FromBank
ORDER BY OutgoingTransactions DESC;


-- Findings:
-- 1. Bank ID 10 has the highest outgoing transaction
--    count, with 2,116 transactions (2.12% of the sample).
-- 2. Banks 10, 1, and 70 collectively account for
--    approximately 6.03% of outgoing transactions.
-- 3. A noticeable decrease in transaction counts occurs
--    between the third- and fourth-ranked banks.
--
-- Limitation:
-- Outgoing transaction counts do not indicate the total
-- monetary value transferred by each bank.



-- ============================================================
-- 9. TOP 10 RECEIVING BANKS
-- ============================================================
-- Business Question:
-- Which banks receive the highest number of
-- incoming transactions?
-- ============================================================

SELECT TOP (10)
    ToBank,
    COUNT(*) AS IncomingTransactions
FROM dbo.Transactions
GROUP BY ToBank
ORDER BY IncomingTransactions DESC;


-- Findings:
-- 1. Bank ID 1 has the highest incoming transaction
--    count, with 1,622 transactions.
-- 2. Bank ID 10 ranks second, with 1,586 incoming
--    transactions.
-- 3. Eight banks appear in both the top 10 sending
--    and top 10 receiving bank rankings.
--
-- Limitation:
-- Transaction counts measure activity frequency,
-- not the total monetary value transferred.



-- ============================================================
-- 10. TOP SENDING AND RECEIVING BANKS COMPARISON
-- ============================================================
-- Business Question:
-- Which banks appear among both the top 10 sending
-- and receiving banks?
-- ============================================================

WITH TopSending AS (
    SELECT TOP (10)
        FromBank AS BankID,
        COUNT(*) AS OutgoingTransactions
    FROM dbo.Transactions
    GROUP BY FromBank
    ORDER BY OutgoingTransactions DESC, FromBank
),
TopReceiving AS (
    SELECT TOP (10)
        ToBank AS BankID,
        COUNT(*) AS IncomingTransactions
    FROM dbo.Transactions
    GROUP BY ToBank
    ORDER BY IncomingTransactions DESC, ToBank
)

SELECT
    s.BankID,
    s.OutgoingTransactions,
    r.IncomingTransactions
FROM TopSending s
INNER JOIN TopReceiving r
    ON s.BankID = r.BankID
ORDER BY s.OutgoingTransactions DESC;


-- Findings:
-- 1. Eight banks appear in both the top 10 sending
--    and receiving bank rankings.
-- 2. Bank ID 10 has the highest outgoing transaction count
--    and the largest outgoing-incoming count difference
--    among these eight banks (+530 transactions).
-- 3. All eight banks recorded more outgoing than incoming
--    transactions in the analyzed sample.
--
-- Limitation:
-- Transaction count differences do not represent net
-- monetary flows or bank profitability.



-- ============================================================
-- 11. BANK TRANSACTION ACTIVITY COMPARISON
-- ============================================================
-- Business Question:
-- Which banks have the largest differences between
-- outgoing and incoming transaction counts?
-- ============================================================

WITH Outgoing AS (
    SELECT
        FromBank AS BankID,
        COUNT(*) AS OutgoingTransactions
    FROM dbo.Transactions
    GROUP BY FromBank
),
Incoming AS (
    SELECT
        ToBank AS BankID,
        COUNT(*) AS IncomingTransactions
    FROM dbo.Transactions
    GROUP BY ToBank
)
SELECT TOP (10)
    COALESCE(o.BankID, i.BankID) AS BankID,
    ISNULL(o.OutgoingTransactions, 0) AS OutgoingTransactions,
    ISNULL(i.IncomingTransactions, 0) AS IncomingTransactions,
    ISNULL(o.OutgoingTransactions, 0)
        - ISNULL(i.IncomingTransactions, 0) AS TransactionDifference
FROM Outgoing o
FULL OUTER JOIN Incoming i
    ON o.BankID = i.BankID
ORDER BY ABS(
    ISNULL(o.OutgoingTransactions, 0)
    - ISNULL(i.IncomingTransactions, 0)
) DESC;


-- Findings:
-- 1. Bank ID 70 has the largest absolute transaction
--    count difference, with 1,924 outgoing transactions
--    and only 3 incoming transactions.
-- 2. Bank ID 10 has the second-largest difference
--    at +530 transactions.
-- 3. All banks in the top 10 results have more
--    outgoing than incoming transactions.
--
-- Recommendation:
-- Investigate Bank ID 70 to understand the unusually
--    large difference in transaction activity.
--
-- Limitation:
-- These differences reflect transaction counts, not
-- monetary net flows or confirmed suspicious activity.



-- ============================================================
-- 12. BANK 70 OUTGOING TRANSACTION INVESTIGATION
-- ============================================================
-- Business Question:
-- Which payment formats are associated with outgoing
-- transactions from Bank ID 70?
-- ============================================================

SELECT
    PaymentFormat,
    COUNT(*) AS OutgoingTransactions
FROM dbo.Transactions
WHERE FromBank = '70'
GROUP BY PaymentFormat
ORDER BY OutgoingTransactions DESC;


-- Findings:
-- 1. Bank ID 70 recorded 1,924 outgoing transactions.
-- 2. Cheque is the most frequent payment format,
--    accounting for approximately 44.96% of outgoing activity.
-- 3. Credit Card and Cash account for approximately
--    28.27% and 26.77%, respectively.
-- 4. No outgoing Reinvestment transactions were observed
--    for Bank ID 70 in the analyzed sample.
--
-- Limitation:
-- Payment format concentration alone does not indicate
-- suspicious or fraudulent banking activity.



-- ============================================================
-- 13. BANK 70 INCOMING TRANSACTION INVESTIGATION
-- ============================================================
-- Business Question:
-- What are the characteristics of incoming transactions
-- received by Bank ID 70?
-- ============================================================

SELECT
    TransactionTimestamp,
    FromBank,
    ToBank,
    AmountReceived,
    ReceivingCurrency,
    PaymentFormat,
    IsLaundering
FROM dbo.Transactions
WHERE ToBank = '70'
ORDER BY TransactionTimestamp;


-- Findings:
-- 1. Bank ID 70 received only 3 transactions in the sample.
-- 2. All incoming transactions used the Cash payment format.
-- 3. Incoming amounts were extremely small:
--    0.07 USD and 0.03 GBP in total.
-- 4. None of these transactions were labelled as laundering.
--
-- Limitation:
-- The analysis covers only the first 100,000 records
-- within a 30-minute period. The observed imbalance
-- cannot establish the bank's normal activity or risk.



-- ============================================================
-- 14. TRANSACTION VOLUME BY MINUTE
-- ============================================================
-- Business Question:
-- How does transaction volume change over time?
-- ============================================================

SELECT
    TransactionTimestamp,
    COUNT(*) AS TransactionCount
FROM dbo.Transactions
GROUP BY TransactionTimestamp
ORDER BY TransactionTimestamp;


-- Findings:
-- 1. Transaction activity remained relatively stable,
--    averaging approximately 3,333 transactions per minute.
-- 2. The highest volume occurred at 00:21,
--    with 3,494 transactions.
-- 3. The lowest volume occurred at 00:08,
--    with 3,212 transactions.
-- 4. No clear upward or downward trend was observed
--    during the analyzed 30-minute period.
--
-- Limitation:
-- The dataset covers only a 30-minute window,
-- which is insufficient to identify daily or
-- long-term transaction patterns.



-- ============================================================
-- 15. TRANSACTION VOLUME SUMMARY
-- ============================================================
-- Business Question:
-- What are the average, minimum, and maximum transaction
-- counts per minute?
-- ============================================================

WITH MinuteCounts AS (
    SELECT
        TransactionTimestamp,
        COUNT(*) AS TransactionCount
    FROM dbo.Transactions
    GROUP BY TransactionTimestamp
)
SELECT
    COUNT(*) AS TotalMinutes,
    AVG(CAST(TransactionCount AS FLOAT))
        AS AvgTransactionsPerMinute,
    MIN(TransactionCount) AS MinTransactionsPerMinute,
    MAX(TransactionCount) AS MaxTransactionsPerMinute
FROM MinuteCounts;


-- Findings:
-- 1. The dataset covers 30 distinct transaction minutes.
-- 2. Average transaction volume was approximately
--    3,333.33 transactions per minute.
-- 3. Transaction counts ranged from 3,212 to 3,494
--    transactions per minute.
-- 4. Transaction activity remained relatively stable
--    during the observed period.
--
-- Limitation:
-- The 30-minute sample is insufficient to identify
-- daily, weekly, or seasonal transaction patterns.



-- ============================================================
-- 16. MONEY LAUNDERING LABEL DISTRIBUTION
-- ============================================================
-- Business Question:
-- What percentage of transactions are labelled
-- as money laundering?
-- ============================================================

SELECT
    IsLaundering,
    COUNT(*) AS TotalTransactions,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
        AS DECIMAL(10,4)
    ) AS TransactionPercentage
FROM dbo.Transactions
GROUP BY IsLaundering
ORDER BY IsLaundering;


-- Findings:
-- 1. Only 5 out of 100,000 transactions were labelled
--    as money laundering (0.0050%).
-- 2. The remaining 99,995 transactions accounted for
--    99.9950% of the dataset.
-- 3. The dataset shows extreme class imbalance.
--
-- Limitation:
-- The analysis is based on the first 100,000 records.
-- The low number of laundering cases limits the
-- reliability of subgroup comparisons and conclusions.


-- ============================================================
-- 17. MONEY LAUNDERING BY PAYMENT FORMAT
-- ============================================================
-- Business Question:
-- How are labelled money laundering transactions
-- distributed across payment formats?
-- ============================================================

SELECT
    PaymentFormat,
    COUNT(*) AS TotalTransactions,
    SUM(
        CASE WHEN IsLaundering = 1 THEN 1 ELSE 0 END
    ) AS LaunderingTransactions,
    CAST(
        SUM(CASE WHEN IsLaundering = 1 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)
        AS DECIMAL(10,4)
    ) AS LaunderingPercentage
FROM dbo.Transactions
GROUP BY PaymentFormat
ORDER BY LaunderingTransactions DESC, PaymentFormat;


-- Findings:
-- 1. Cheque and Credit Card each recorded 2 labelled
--    laundering transactions, accounting for 80% of
--    all labelled cases combined.
-- 2. Cash had the highest observed laundering rate
--    at 0.0375%, but only 1 labelled transaction.
-- 3. ACH, Bitcoin, Reinvestment, and Wire had no
--    labelled laundering transactions in the sample.
--
-- Limitation:
-- Only 5 transactions were labelled as laundering.
-- These small counts are insufficient to establish
-- reliable risk differences between payment formats.
-- A zero observed rate does not imply zero risk.



-- ============================================================
-- 18. LABELLED MONEY LAUNDERING TRANSACTIONS
-- ============================================================
-- Business Question:
-- What are the characteristics of transactions
-- labelled as money laundering?
-- ============================================================

SELECT
    TransactionID,
    TransactionTimestamp,
    FromBank,
    ToBank,
    AmountPaid,
    PaymentCurrency,
    AmountReceived,
    ReceivingCurrency,
    PaymentFormat,
    IsLaundering
FROM dbo.Transactions
WHERE IsLaundering = 1
ORDER BY TransactionTimestamp;


-- Findings:
-- 1. All five labelled laundering transactions
--    originated from Bank ID 70.
-- 2. These transactions involved five different
--    receiving banks.
-- 3. Labelled transaction amounts ranged from
--    $792.92 to approximately $13.17 million USD.
-- 4. The transactions used Cheque, Credit Card,
--    and Cash payment formats.
-- 5. All five transactions were denominated in USD.
--
-- Recommendation:
-- Investigate the relationship between Bank ID 70's
-- outgoing activity and labelled laundering cases.
--
-- Limitation:
-- The dataset is synthetic and contains only five
-- labelled cases in the analyzed sample.
-- These findings do not establish causal relationships
-- or real-world banking risk.



-- ============================================================
-- 19. LAUNDERING CONCENTRATION BY SENDING BANK
-- ============================================================
-- Business Question:
-- Which sending banks have labelled money laundering
-- transactions, and what percentage of their outgoing
-- transactions are labelled?
-- ============================================================

SELECT
    FromBank,
    COUNT(*) AS TotalOutgoingTransactions,
    SUM(
        CASE WHEN IsLaundering = 1 THEN 1 ELSE 0 END
    ) AS LaunderingTransactions,
    CAST(
        SUM(CASE WHEN IsLaundering = 1 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)
        AS DECIMAL(10,4)
    ) AS LaunderingPercentage
FROM dbo.Transactions
GROUP BY FromBank
HAVING SUM(
    CASE WHEN IsLaundering = 1 THEN 1 ELSE 0 END
) > 0
ORDER BY LaunderingTransactions DESC;


-- Findings:
-- 1. Bank ID 70 is the only sending bank associated
--    with labelled laundering transactions in the sample.
-- 2. All 5 labelled laundering transactions originated
--    from Bank ID 70.
-- 3. The observed laundering rate for Bank ID 70 was
--    0.2599% (5 out of 1,924 outgoing transactions).
-- 4. Bank ID 70 also showed the largest difference
--    between outgoing and incoming transaction counts.
--
-- Limitation:
-- These results are based on synthetic data and only
-- five labelled cases within a 30-minute sample.
-- The observed concentration does not establish
-- causation or real-world banking risk.



-- ============================================================
-- 20. FINAL DATASET SUMMARY
-- ============================================================
-- Objective:
-- Confirm the final dataset scope before Power BI reporting.
-- ============================================================

SELECT
    COUNT(*) AS TotalTransactions,
    COUNT(DISTINCT PaymentFormat) AS PaymentFormats,
    COUNT(DISTINCT PaymentCurrency) AS PaymentCurrencies,
    MIN(TransactionTimestamp) AS EarliestTransaction,
    MAX(TransactionTimestamp) AS LatestTransaction,
    SUM(CASE WHEN IsLaundering = 1 THEN 1 ELSE 0 END)
        AS LaunderingTransactions
FROM dbo.Transactions;

