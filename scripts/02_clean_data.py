import pandas as pd

file_path = "data/raw/Online Retail.xlsx"
df = pd.read_excel(file_path)

# print(df.shape)

df_cleaned = df.drop_duplicates()

# print(df_cleaned.shape)

stock_adjustments = df_cleaned[df_cleaned["Description"].isna()].copy()

df_cleaned = df_cleaned[df_cleaned["Description"].notna()].copy()

# print("Stock adjustments:", stock_adjustments.shape)
# print("Sales data after removing blank descriptions:", df_cleaned.shape)

df_cleaned["CustomerID"] = df_cleaned["CustomerID"].astype("Int64")

# print(df_cleaned["CustomerID"].dtype)
# print(df_cleaned["CustomerID"].head(10))

# print(df.dtypes)
# print("**" * 50)
# print(df_cleaned.dtypes)

non_commercial = df_cleaned[df_cleaned["UnitPrice"] <= 0].copy()

df_cleaned = df_cleaned[df_cleaned["UnitPrice"] > 0].copy()

# print("Non-commercial rows:", non_commercial.shape)
# print("Paid transactions:", df_cleaned.shape)


# Check whether negative quantities and InvoiceNo values starting with "C"
# identify the same return/cancellation transactions.

negative_quantity = df_cleaned["Quantity"] < 0
cancelled_invoice = df_cleaned["InvoiceNo"].astype(str).str.startswith("C")

# print("Negative quantity rows:", negative_quantity.sum())
# print("Invoices starting with C:", cancelled_invoice.sum())
# print("Rows matching both:", (negative_quantity & cancelled_invoice).sum())


df_cleaned["transaction_type"] = "sale"
df_cleaned.loc[
    df_cleaned["Quantity"] < 0,
    "transaction_type"
] = "return/cancellation"

# Count each transaction type and confirm that returns equal 9,251 rows.

# print(df_cleaned["transaction_type"].value_counts())


df_cleaned["transaction_value"] = df_cleaned["Quantity"] *df_cleaned["UnitPrice"]
# print(df_cleaned["transaction_value"].head(10))
        

# Validate the cleaned dataset before exporting it.


# df_cleaned.info()
# print("**" * 50)
# print("Shape:", df_cleaned.shape)
# print("**" * 50)
# print("Duplicate rows:", df_cleaned.duplicated().sum())
# print("**" * 50)
# print("Missing descriptions:", df_cleaned["Description"].isna().sum())
# print("**" * 50)
# print("Non-positive prices:", (df_cleaned["UnitPrice"] <= 0).sum())
# print("**" * 50)
# print("Zero quantities:", (df_cleaned["Quantity"] == 0).sum())
# print("**" * 50)
# print(df_cleaned["transaction_type"].value_counts())
# print("**" * 50)
# print("Incorrect sale values:",
#       ((df_cleaned["transaction_type"] == "sale") &
#        (df_cleaned["transaction_value"] <= 0)).sum())
# print("Incorrect return values:",
#       ((df_cleaned["transaction_type"] == "return/cancellation") &
#        (df_cleaned["transaction_value"] >= 0)).sum())


# Export the cleaned and separated datasets to the processed-data folder.

df_cleaned.to_csv("data/processed/cleaned_sales_data.csv", index=False)
stock_adjustments.to_csv("data/processed/stock_adjustments.csv", index=False)
non_commercial.to_csv("data/processed/non_commercial_data.csv", index=False)
print("Cleaned datasets exported to the processed-data folder.")