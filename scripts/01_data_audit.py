import pandas as pd 

file_path = "data/raw/Online Retail.xlsx"

df = pd.read_excel(file_path, sheet_name="Online Retail")
#print(df.head())

#print(df.info())
#print("**" * 50)
# print(df.shape)
# print("**" * 50)
# print(df.dtypes)
# print("**" * 50)
#print(df.describe())
# print(df.isnull().sum())

# print(df.duplicated().sum())

# print(df[df.duplicated(keep=False)].head(10))

# missing_description = df[df["Description"].isna()]
# print(missing_description)

missing_description = df[df["Description"].isna()]

# print(missing_description.shape)
# print(missing_description.head(15).to_string())

# print("Rows:", len(missing_description))
# print("Zero price:", (missing_description["UnitPrice"] == 0).sum())
# print("Missing customer:", missing_description["CustomerID"].isna().sum())

missing_customer = df[df["CustomerID"].isna()]

valid_unknown_sales = missing_customer[
    (missing_customer["Quantity"] > 0) &
    (missing_customer["UnitPrice"] > 0)
]

# print("Missing CustomerID rows:", len(missing_customer))
# print("Valid sales without CustomerID:", len(valid_unknown_sales))


other_missing_customer = missing_customer[
    ~(
        (missing_customer["Quantity"] > 0) &
        (missing_customer["UnitPrice"] > 0)
    )
]

# print("Other rows:", len(other_missing_customer))
# print("Negative quantity:", (other_missing_customer["Quantity"] < 0).sum())
# print("Zero price:", (other_missing_customer["UnitPrice"] == 0).sum())


negative_zero_price = other_missing_customer[
    (other_missing_customer["Quantity"] < 0) &
    (other_missing_customer["UnitPrice"] == 0)
]

negative_paid = other_missing_customer[
    (other_missing_customer["Quantity"] < 0) &
    (other_missing_customer["UnitPrice"] > 0)
]

positive_zero_price = other_missing_customer[
    (other_missing_customer["Quantity"] > 0) &
    (other_missing_customer["UnitPrice"] == 0)
]

unclassified = other_missing_customer[
    ~(
        ((other_missing_customer["Quantity"] < 0) & (other_missing_customer["UnitPrice"] == 0)) |
        ((other_missing_customer["Quantity"] < 0) & (other_missing_customer["UnitPrice"] > 0)) |
        ((other_missing_customer["Quantity"] > 0) & (other_missing_customer["UnitPrice"] == 0))
    )
]

print(unclassified.to_string(index=False))