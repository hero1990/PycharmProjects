import xlrd
import fire

def strs(row):
    values = "";
    for i in range(len(row)):
        if i == len(row) - 1:
            values = values + str(row[i])
        else:
            values = values + str(row[i]) + "jack"
    return values


def transfer():
    # 打开文件
    data = xlrd.open_workbook("LCD  HP PO.xlsx")
    output = open("1.txt", "w")  # 覆盖

    table = data.sheets()[0]  # 表头
    nrows = table.nrows  # 行数
    ncols = table.ncols  # 列数
    colnames = table.row_values(0)  # 某一行数据
    # 打印出行数列数
    print(nrows)
    print(ncols)
    print(colnames)
    for ronum in range(1, nrows):
        row = table.row_values(ronum)
        print(row)
        new = list()
        for i in row[0:10]:
            if type(i) == float:
                new.append(int(i))
            else:
                new.append(i)

        values = strs(new)  # 条用函数，将行数据拼接成字符串
        values = "".join(values.split()).replace("jack", "\t")
        print(values)
        output.writelines(values + "\r")  # 将字符串写入新文件
    output.close()  # 关闭写入的文件

if __name__ == '__main__':
    fire.Fire(transfer)