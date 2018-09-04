
import pandas as pd

FeiXiaoHao = pd.read_html("http://www.feixiaohao.com/all", encoding='UTF-8')[0]
file_name = "test.xlsx"
dret = pd.DataFrame.from_records(FeiXiaoHao)
dret.to_excel(file_name, "test", engine="openpyxl")
