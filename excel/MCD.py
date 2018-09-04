import xlrd

wb = xlrd.open_workbook('HP CONNECTOR.xls')
sheet = wb.sheet_by_name('Sheet1')

def filterdata (sh, para):

    values = sh.row_values
    print (values(1, 1))
    data = [values(r, 0)[0:10] for r in range(sh.nrows) if values(r, 0)[10] == para]
    return data


print(filterdata(sheet, 'CQWW'))
