import os
import re


filelist = []
for i in os.listdir("."):
    if os.path.splitext(i)[1] in [".sql", ".SQL"]:
        filelist.append(i)
print(filelist)
    # 打开文件
for i in filelist:
    (fileName, extension) = os.path.splitext(i)
    with open(i, 'r+', encoding="utf-8", errors="ignore") as f:
        sql_list = f.read()
        sql_list = sql_list.replace('\u0000', '').replace('\x00', '').strip('[ \n]')
        print(sql_list[-2:].upper())
        print(re.sub(r'\s+', ' ', sql_list[sql_list.index('ALTER'):sql_list.index('PROC')]))
        if sql_list[-2:].upper() == 'GO':
            try:
                sql_list = sql_list[:sql_list.index('ALTER')] + \
                           re.sub(r'\s+', ' ', sql_list[sql_list.index('ALTER'):sql_list.index('PROCEDURE')]) + \
                           sql_list[sql_list.index('PROC'):]
                print(sql_list.index('ALTER PROCEDURE'))
                sql_list = sql_list[sql_list.index('ALTER PROCEDURE'):-2]
            except ValueError as e:
                print('No Keyword PROCEDURE,using PROC')
            finally:
                sql_list = sql_list[:sql_list.index('ALTER')] + \
                           re.sub(r'\s+', ' ', sql_list[sql_list.index('ALTER'):sql_list.index('PROC')]) + \
                           sql_list[sql_list.index('PROC'):]
                print(sql_list.index('ALTER PROC'))
                sql_list = sql_list[sql_list.index('ALTER PROC'):-2]
        else:
            try:
                sql_list = sql_list[:sql_list.index('ALTER')] + \
                           re.sub(r'\s+', ' ', sql_list[sql_list.index('ALTER'):sql_list.index('PROCEDURE')]) + \
                           sql_list[sql_list.index('PROC'):]
                print(sql_list.index('ALTER PROCEDURE'))
                sql_list = sql_list[sql_list.index('ALTER PROCEDURE'):]
            except ValueError as e:
                print('No Keyword PROCEDURE,using PROC')
            finally:
                sql_list = sql_list[:sql_list.index('ALTER')] + \
                           re.sub(r'\s+', ' ', sql_list[sql_list.index('ALTER'):sql_list.index('PROC')]) + \
                           sql_list[sql_list.index('PROC'):]
                print(sql_list.index('ALTER PROC'))
                sql_list = sql_list[sql_list.index('ALTER PROC'):]
        print(sql_list)


