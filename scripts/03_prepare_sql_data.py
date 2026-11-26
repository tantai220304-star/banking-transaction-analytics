
"""
============================================================
BANKING TRANSACTION ANALYTICS
03 - DATA PREPARATION & SOURCE VALIDATION
============================================================

Project:
    Banking Transaction Analytics

Script:
    03_prepare_sql_data.py

Objective:
    Prepare banking transaction records for SQL Server
    import and validate the processed source dataset.

Data Source:
    IBM Synthetic Financial Transactions Dataset

Workflow:
    1. Load the first 100,000 transaction records.
    2. Rename columns to match the SQL Server schema.
    3. Validate and standardize transaction timestamps.
    4. Export the prepared dataset to CSV.
    5. Verify the exported dataset.
    6. Investigate transaction amount precision.
    7. Generate source reconciliation metrics.
    8. Validate currency-level totals.
    9. Check duplicate transaction records.

Output:
    data/processed/banking_transactions_100k.csv

Limitation:
    The first 100,000 records may not represent
    the full dataset.
============================================================
"""

# ============================================================
# 1. PROJECT CONFIGURATION
# ============================================================

from pathlib import Path
from decimal import Decimal
import pandas as pd

# Define project paths
project_root = Path(__file__).resolve().parent.parent

raw_file = project_root / "data/raw/HI-Small_Trans.csv"

output_file = (
    project_root
    / "data/processed/banking_transactions_100k.csv"
)


# ============================================================
# 2. DATA PREPARATION
# ============================================================
# Objective:
# Prepare the first 100,000 transactions for SSIS import.

# 2.1 Load source data
df_sql = pd.read_csv(raw_file, nrows=100000)

# 2.2 Rename columns to match SQL Server schema
df_sql = df_sql.rename(columns={
    "Timestamp": "TransactionTimestamp",
    "From Bank": "FromBank",
    "Account": "FromAccount",
    "To Bank": "ToBank",
    "Account.1": "ToAccount",
    "Amount Received": "AmountReceived",
    "Receiving Currency": "ReceivingCurrency",
    "Amount Paid": "AmountPaid",
    "Payment Currency": "PaymentCurrency",
    "Payment Format": "PaymentFormat",
    "Is Laundering": "IsLaundering"
})

# 2.3 Standardize transaction timestamps
df_sql["TransactionTimestamp"] = pd.to_datetime(
    df_sql["TransactionTimestamp"],
    format="%Y/%m/%d %H:%M",
    errors="coerce"
)

# 2.4 Validate timestamp conversion
invalid_count = df_sql["TransactionTimestamp"].isna().sum()

if invalid_count > 0:
    raise ValueError(
        f"Invalid transaction timestamps detected: {invalid_count}"
    )

# 2.5 Format timestamps for SQL Server
df_sql["TransactionTimestamp"] = (
    df_sql["TransactionTimestamp"]
    .dt.strftime("%Y-%m-%d %H:%M:%S")
)

# 2.6 Export processed data
output_file.parent.mkdir(parents=True, exist_ok=True)

df_sql.to_csv(output_file, index=False)

print(f"Exported Records: {len(df_sql):,}")
print(f"Saved to: {output_file}")


# ============================================================
# 3. EXPORTED DATA VALIDATION
# ============================================================
# Objective:
# Verify the exported CSV structure and data quality.

df_check = pd.read_csv(output_file)

# 3.1 Validate dataset dimensions
print("\n--- EXPORTED DATA VALIDATION ---")
print("Rows:", len(df_check))
print("Columns:", df_check.shape[1])

# 3.2 Verify column names
print("\nColumn Names:")
print(df_check.columns.tolist())

# 3.3 Check missing values
print("\nMissing Values:", df_check.isna().sum().sum())

# 3.4 Preview exported records
print("\nData Preview:")
print(df_check.head())


# ============================================================
# 4. DECIMAL PRECISION VALIDATION
# ============================================================
# Objective:
# Identify the decimal precision required to preserve
# transaction amounts during the SSIS ETL process.

# 4.1 Investigate the previously affected Bitcoin record
# Note: Row position is based on the initial CSV load order.

transaction_row = df_sql.iloc[58473]

print("\n--- BITCOIN TRANSACTION INVESTIGATION ---")

print(transaction_row[[
    "TransactionTimestamp",
    "AmountPaid",
    "PaymentCurrency",
    "AmountReceived",
    "ReceivingCurrency",
    "PaymentFormat"
]])

# 4.2 Load original amount values as strings
df_precision = pd.read_csv(
    raw_file,
    nrows=100000,
    usecols=["Amount Paid", "Amount Received"],
    dtype=str
)

# 4.3 Check decimal places for each amount column
print("\n--- DECIMAL PRECISION VALIDATION ---")

for col in ["Amount Paid", "Amount Received"]:
    values = df_precision[col].dropna()

    decimal_places = values.map(
        lambda x: max(
            0,
            -Decimal(x).as_tuple().exponent
        )
    )

    print(f"\n{col}")
    print("Maximum Decimal Places:", decimal_places.max())
    print(
        "Values Exceeding 8 Decimal Places:",
        (decimal_places > 8).sum()
    )


# ============================================================
# 5. SOURCE DATA RECONCILIATION
# ============================================================
# Objective:
# Generate source metrics for comparison with SQL Server.
#
# Decimal is used to preserve exact monetary values.

# 5.1 Load processed CSV with amount columns as strings
df_source = pd.read_csv(
    output_file,
    dtype={
        "AmountPaid": str,
        "AmountReceived": str
    }
)

# 5.2 Validate transaction count
print("\n--- SOURCE DATA RECONCILIATION ---")
print("Total Transactions:", len(df_source))

# 5.3 Calculate monetary aggregates
for col in ["AmountPaid", "AmountReceived"]:
    amounts = df_source[col].map(Decimal)

    print(f"\n{col}")
    print("Total:", sum(amounts))
    print("Minimum:", min(amounts))
    print("Maximum:", max(amounts))

# 5.4 Count labelled laundering transactions
print(
    "\nLaundering Transactions:",
    (df_source["IsLaundering"] == 1).sum()
)


# ============================================================
# 6. CURRENCY-LEVEL SOURCE RECONCILIATION
# ============================================================
# Objective:
# Validate transaction counts and total amounts
# separately for each payment currency.

currency_summary = (
    df_source
    .groupby("PaymentCurrency")
    .agg(
        TransactionCount=("AmountPaid", "size"),
        TotalAmountPaid=(
            "AmountPaid",
            lambda values: sum(
                Decimal(value) for value in values
            )
        )
    )
    .reset_index()
    .sort_values("PaymentCurrency")
)

print("\n--- CURRENCY-LEVEL RECONCILIATION ---")
print(currency_summary.to_string(index=False))


# ============================================================
# 7. SOURCE DUPLICATE VALIDATION
# ============================================================
# Objective:
# Identify fully duplicated transaction records
# in the processed CSV source.

# 7.1 Count total records
total_records = len(df_source)

# 7.2 Count duplicated records
duplicate_records = df_source.duplicated().sum()

# 7.3 Calculate unique record groups
unique_record_groups = total_records - duplicate_records

# 7.4 Display duplicate validation results
print("\n--- SOURCE DUPLICATE VALIDATION ---")
print("Total Records:", total_records)
print("Unique Record Groups:", unique_record_groups)
print("Duplicate Records:", duplicate_records)
