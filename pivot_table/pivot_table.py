import pandas as pd
import numpy as np

df = pd.read_excel("C:\Users\nwgq2jchen1\PycharmProjects\sales-funnel.xlsx")
df.head()
df["Status"] = df["Status"].astype("category")
df["Status"].cat.set_categories(["won", "pending", "presented", "declined"], inplace=True)
pd.pivot_table(df, index=["Name"])
pd.pivot_table(df, index=["Name", "Rep", "Manager"])
pd.pivot_table(df, index=["Manager", "Rep"])
pd.pivot_table(df, index=["Manager", "Rep"], values=["Price"])
pd.pivot_table(df, index=["Manager", "Rep"], values=["Price"], aggfunc=np.sum)
pd.pivot_table(df, index=["Manager", "Rep"], values=["Price"], aggfunc=[np.mean, len])
pd.pivot_table(df, index=["Manager", "Rep"], values=["Price"], columns=["Product"], aggfunc=[np.sum])
pd.pivot_table(df, index=["Manager", "Rep"], values=["Price"], columns=["Product"], aggfunc=[np.sum], fill_value=0)
pd.pivot_table(df, index=["Manager", "Rep"], values=["Price", "Quantity"], columns=["Product"], aggfunc=[np.sum], fill_value=0)
pd.pivot_table(df, index=["Manager", "Rep", "Product"], values=["Price", "Quantity"], aggfunc=[np.sum], fill_value=0)

pd.pivot_table(df, index=["Manager", "Rep", "Product"], values=["Price", "Quantity"], aggfunc=[np.sum, np.mean], fill_value=0, margins=True)

pd.pivot_table(df, index=["Manager", "Status"], values=["Price"], aggfunc=[np.sum], fill_value=0, margins=True)

pd.pivot_table(df, index=["Manager", "Status"], columns=["Product"], values=["Quantity", "Price"],
               aggfunc={"Quantity": len, "Price": np.sum}, fill_value=0)

table = pd.pivot_table(df, index=["Manager", "Status"], columns=["Product"], values=["Quantity", "Price"], aggfunc={"Quantity": len, "Price": [np.sum, np.mean]}, fill_value=0)


table.query('Manager == ["Debra Henley"]')

table.query('Status == ["pending","won"]')
