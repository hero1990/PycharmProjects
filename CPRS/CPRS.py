
import pandas as pd

cprs = pd.read_csv("Book1.csv").fillna(0)

df = cprs.groupby(by=['Site'])['amount'].sum()

df = pd.DataFrame(cprs, columns=['Site'])

df = pd.DataFrame(cprs, columns=['Site'])
