import pymssql
import os
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

    def __getconnect(self):
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

    def execquery(self, sql):
        """
        执行查询语句
        返回的是一个包含tuple的list，list的元素是记录行，tuple的元素是每行记录的字段

        调用示例：
                ms = MSSQL(host="localhost",user="sa",pwd="123456",db="PythonWeiboStatistics")
                resList = ms.ExecQuery("SELECT id,NickName FROM WeiBoUser")
                for (id,NickName) in resList:
                    print str(id),NickName
        """
        cur = self.__getconnect()
        cur.execute(sql)
        res_list = cur.fetchall()

        # 查询完毕后必须关闭连接
        self.conn.close()
        return res_list

    def execnonquery(self, sql):
        """
        执行非查询语句

        调用示例：
            cur = self.__GetConnect()
            cur.execute(sql)
            self.conn.commit()
            self.conn.close()
        """
        cur = self.__getconnect()
        cur.execute(sql)
        self.conn.commit()
        self.conn.close()


def main():

    ms = MSSQL(host="10.213.27.220", user="sa", pwd="mssql", db="KoneSH")

    timestamp = time.strftime('%Y%m%d%H%M%S', time.localtime(time.time()))
    base_folder = os.getcwd() + "\\"
    archive_folder = os.getcwd() + "\\archive\\" + timestamp + "\\"
    fail_folder = os.getcwd() + "\\fail\\" + timestamp + "\\"
    log_folder = os.getcwd() + "\\logs\\" + timestamp + "\\"
    os.makedirs(archive_folder)
    os.makedirs(fail_folder)
    os.makedirs(log_folder)
    logfile_name = log_folder + timestamp + ".log"  # 创建logfile,一个批次的导入记入一个log file
    logging.basicConfig(filename=logfile_name, level=logging.INFO, format='%(asctime)s - %(levelname)s: %(message)s')

    file_list = []
    for i in os.listdir("."):
        if os.path.splitext(i)[1] in [".sql", ".SQL"]:
            file_list.append(i)
    print(file_list)
    # 打开文件
    for i in file_list:
        with open(i, 'r+', encoding="utf-8-sig", errors="ignore") as f:
            sql_list = f.read()
            sql_list = sql_list.replace('\u0000', '').replace('\x00', '').replace('\xef\xbb\xbf', '').strip('[ \n]')
            print(sql_list[-2:].upper())
            if sql_list[-2:].upper() == 'GO':
                sql_list = sql_list[sql_list:-2]
            print(sql_list)
            f.close()

            try:
                ms.execnonquery(sql_list)
            except pymssql.DatabaseError as e:
                print(e)  # re-raise real error
                logging.info("File:" + i + " Error,please check")
                logging.info(e)
                shutil.move(base_folder + i, fail_folder + i)
                # raise e
            finally:
                # shutil.move(base_folder + i, failfolder + i)
                print(1)

            if os.path.exists(i) is True:
                logging.info("File: " + i + " successfully")
                shutil.move(base_folder + i, archive_folder + i)


if __name__ == '__main__':
    main()
