import pymssql
import os
import re
import time
import logging
import shutil


class MSSQL:
    """
    对pymssql的简单封装
    pymssql库，该库到这里下载：http://www.lfd.uci.edu/~gohlke/pythonlibs/#pymssql
    使用该库时，需要在Sql Server Configuration Manager里面将TCP/IP协议开启

    用法：

    """

    def __init__(self, host, user, pwd, db):
        self.host = host
        self.user = user
        self.pwd = pwd
        self.db = db

    def __GetConnect(self):
        """
        得到连接信息
        返回: conn.cursor()
        """
        if not self.db:
            raise(NameError, "没有设置数据库信息")
        self.conn = pymssql.connect(host=self.host, user=self.user, password=self.pwd, database=self.db, charset="utf8")
        cur = self.conn.cursor()
        if not cur:
            raise(NameError, "连接数据库失败")
        else:
            return cur

    def ExecQuery(self, sql):
        """
        执行查询语句
        返回的是一个包含tuple的list，list的元素是记录行，tuple的元素是每行记录的字段

        调用示例：
                ms = MSSQL(host="localhost",user="sa",pwd="123456",db="PythonWeiboStatistics")
                resList = ms.ExecQuery("SELECT id,NickName FROM WeiBoUser")
                for (id,NickName) in resList:
                    print str(id),NickName
        """
        cur = self.__GetConnect()
        cur.execute(sql)
        resList = cur.fetchall()

        #查询完毕后必须关闭连接
        self.conn.close()
        return resList

    def ExecNonQuery(self, sql):
        """
        执行非查询语句

        调用示例：
            cur = self.__GetConnect()
            cur.execute(sql)
            self.conn.commit()
            self.conn.close()
        """
        cur = self.__GetConnect()
        cur.execute(sql)
        self.conn.commit()
        self.conn.close()


def main():

    ms = MSSQL(host="10.213.27.220", user="sa", pwd="mssql", db="KoneSH")

    timeStamp = time.strftime('%Y%m%d%H%M%S', time.localtime(time.time()))
    basefolder = os.getcwd() + "\\"
    archivefolder = os.getcwd() + "\\archive\\" + timeStamp + "\\"
    failfolder = os.getcwd() + "\\fail\\" + timeStamp + "\\"
    logFolder = os.getcwd() + "\\logs\\" + timeStamp + "\\"
    os.makedirs(archivefolder)
    os.makedirs(failfolder)
    os.makedirs(logFolder)
    logFileName = logFolder + timeStamp + ".log"  # 创建logfile,一个批次的导入记入一个log file
    logging.basicConfig(filename=logFileName, level=logging.INFO, format='%(asctime)s - %(levelname)s: %(message)s')

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
            if sql_list[-2:].upper() == 'GO':
                sql_list = sql(sql_list, 'ALTER', -2, )
            else:
                sql_list = sql(sql_list, 'ALTER', None)
            print(sql_list)
            f.close()

            try:
                ms.ExecNonQuery(sql_list)
            except pymssql.DatabaseError as e:
                print(e)  # re-raise real error
                raise e
                shutil.move(basefolder + i, failfolder + i)
            finally:
                shutil.move(basefolder + i, archivefolder + i)


def sql(sql_list, keyword, end):
    try:
        sql_list = sql_list[:sql_list.index(keyword)] + \
                   re.sub(r'\s+', ' ', sql_list[sql_list.index(keyword):sql_list.index('PROCEDURE')]) + \
                   sql_list[sql_list.index('PROC'):]
        print(sql_list.index(keyword + ' ' + 'PROCEDURE'))
        sql_list = sql_list[sql_list.index(keyword + ' ' + 'PROCEDURE'):end]
    except ValueError as e:
        print('No Keyword PROCEDURE,using PROC')
    finally:
        sql_list = sql_list[:sql_list.index(keyword)] + \
                   re.sub(r'\s+', ' ', sql_list[sql_list.index(keyword):sql_list.index('PROC')]) + \
                   sql_list[sql_list.index('PROC'):]
        print(sql_list.index(keyword + ' ' + 'PROC'))
        sql_list = sql_list[sql_list.index(keyword + ' ' + 'PROC'):end]
    return sql_list


if __name__ == '__main__':
    main()
