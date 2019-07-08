
import pandas as pd

CR = pd.read_html("http://10.215.20.178:8095/display/NGWII/Change+Request", encoding='UTF-8')[1]
file_name = "CR.xlsx"
dret = pd.DataFrame.from_records(CR)
dret.to_excel(file_name, "test", engine="openpyxl")


BUG = pd.read_html("http://10.215.20.178:8095/display/NGWII/Change+Request", encoding='UTF-8')[3]
file_name = "BUG.xlsx"
dret = pd.DataFrame.from_records(BUG)
dret.to_excel(file_name, "test", engine="openpyxl")