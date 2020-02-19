import pandas as pd

data = pd.read_csv('1sch.csv')
data = data["length_width_height"].str.split(',',expand = True)
print(data)
data.to_excel('1236.xlsx')

