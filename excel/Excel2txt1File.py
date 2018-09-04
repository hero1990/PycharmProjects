import xlrd
import os
import shutil
import time
import logging
from configration import *
import fire


def strs(row):
    value = ""
    for k in range(len(row)):
        if k == len(row) - 1:
            value = value + str(row[k])
        else:
            value = value + str(row[k]) + "j!a@c#k"
    return value


def transfer():

    timeStamp = time.strftime('%Y%m%d%H%M%S', time.localtime(time.time()))
    baseFolder = os.getcwd() + "\\"
    outFolder = os.getcwd() + "\out\\"
    archiveFolder = os.getcwd() + "\\archive\\" + timeStamp + "\\"
    logFolder = os.getcwd() + "\\logs\\" + timeStamp + "\\"
    os.makedirs(archiveFolder)
    os.makedirs(logFolder)
    logFileName = logFolder + timeStamp + ".log"  # 创建logfile,一个批次的导入记入一个log file
    logging.basicConfig(filename=logFileName, level=logging.INFO, format='%(asctime)s - %(levelname)s: %(message)s')

    fileList = []
    for i in os.listdir("."):
        # if os.path.splitext(i)[1] == ".xlsx":
        #     fileList.append(i)
        # elif os.path.splitext(i)[1] == ".xls":
        #     fileList.append(i)
        if os.path.splitext(i)[1] in [".xlsx",".xls",".XLSX",".XLS"]:
            fileList.append(i)

    print(fileList)
# 打开文件
    for i in fileList:
        (fileName, extension) = os.path.splitext(i)
        if fileName.find("HP") == -1:
            name = "ODMPO_" + timeStamp + ".txt"
        else:
            name = "HPPO_" + timeStamp + ".txt"
        logging.info("文件名：" + i)
        data = xlrd.open_workbook(i)
        output = open(outFolder + name, "a")  # 追加

        table = data.sheets()[0]  # sheet1   还可以用sheet_by_name('Sheet1')
        nrows = table.nrows  # 行数
        ncols = table.ncols  # 列数
        colnames = table.row_values(0)  # 某一行数据
        count = 0
        # 打印出行数列数
        logging.info("总行数：" + str(nrows-1))

        for ronum in range(1, nrows):
            row = table.row_values(ronum)
            #condition = ['WHFXN']
            if row[10].upper() in condition:
                count = count + 1
                new = list()
                for columm in row[0:8]:
                    if type(columm) == float:
                        new.append(int(columm))
                    else:
                        new.append(columm)
                for columm in row[8:10]:
                    if ".0" == str(columm)[-2:]:
                        new.append(int(columm))
                    else:
                        new.append(columm)
                values = strs(new)  # 条用函数，将行数据拼接成字符串
                values = "".join(values.split()).replace("j!a@c#k", "\t")
                output.writelines(values + "\n")  # 将字符串写入新文件
        output.close()  # 关闭写入的文件
        logging.info(str(condition) + ":" + str(count))
        shutil.move(baseFolder + i, archiveFolder + i)
        print(baseFolder + i)
        print(os.getcwd() + "\\archive\\" + i)
        logging.info("---------------------------------------------------------------------------------")



if __name__ == '__main__':
    fire.Fire(transfer)