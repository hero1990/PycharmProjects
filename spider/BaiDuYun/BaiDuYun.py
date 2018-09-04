# -*- coding:utf-8 -*-
import requests
import json
import time
import re
from selenium import webdriver
import os


class BaiduYunTransfer:

    headers = None
    bdstoken = None

    def __init__(self, bduss, stoken, bdstoken):
        self.bdstoken = bdstoken
        self.headers = {
            'Accept': '*/*',
            'Accept-Encoding': 'gzip, deflate, br',
            'Accept-Language': 'zh-CN,zh;q=0.8',
            'Connection': 'keep-alive',
            'Content-Length': '161',
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'Cookie': 'BDUSS=%s;STOKEN=%s;' % (bduss, stoken),
            'Host': 'pan.baidu.com',
            'Origin': 'https://pan.baidu.com',
            'Referer': 'https://pan.baidu.com/s/1dFKSuRn?errno=0&errmsg=Auth%20Login%20Sucess&&bduss=&ssnerror=0',
            'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.84 Safari/537.36',
            'X-Requested-With': 'XMLHttpRequest',
        }

    def transfer(self, share_id, uk, filelist_str, path_t_save):
        # 通用参数
        ondup = "newcopy"
        async = "1"
        channel = "chunlei"
        clienttype = "0"
        web = "1"
        app_id = "250528"
        logid = "MTUxNDg3MjUwMTQ4NTAuNzQyNDMxOTAxMDU3NjE3Nw"

        url_trans = "https://pan.baidu.com/share/transfer?shareid=%s" \
                    "&from=%s" \
                    "&ondup=%s" \
                    "&async=%s" \
                    "&bdstoken=%s" \
                    "&channel=%s" \
                    "&clienttype=%s" \
                    "&web=%s" \
                    "&app_id=%s" \
                    "&logid=%s" % (share_id, uk, ondup, async, self.bdstoken, channel, clienttype, web, app_id, logid)

        form_data = {
            'filelist': filelist_str,
            'path': path_t_save,
        }

        response = requests.post(url_trans, data=form_data, headers=self.headers)
        print(response.content)

        jsob = json.loads(response.content)

        if "errno" in jsob:
            return jsob["errno"]
        else:
            return None

    def get_file_info(self, url):

        executable_path = "C:\Program Files (x86)\Google\Chrome\Application\chromedriver.exe"
        os.environ["webdriver.chrome.driver"] = executable_path
        options = webdriver.ChromeOptions()
        options.add_argument("--user-data-dir=" + r"C:/Users/nwgq2jchen1/AppData/Local/Google/Chrome/User Data/")
        driver = webdriver.Chrome(executable_path, chrome_options=options)

        print (u"尝试打开")
        driver.get(url)
        time.sleep(1)
        print(u"正式打开链接")
        driver.get(url)
        print(u"成功获取并加载页面")
        script_list = driver.find_elements_by_xpath("//body/script")
        innerHTML = script_list[-1].get_attribute("innerHTML")
        # [\s\S]*可以匹配包括换行的所有字符,\s表示空格，\S表示非空格字符
        pattern = 'yunData.SHARE_ID = "(.*?)"[\s\S]*yunData.SHARE_UK = "(.*?)"[\s\S]*yunData.FILEINFO = (.*?);[\s\S]*'
        srch_ob = re.search(pattern, innerHTML)

        share_id = srch_ob.group(1)
        share_uk = srch_ob.group(2)

        file_info_jsls = json.loads(srch_ob.group(3))
        path_list_str = u'['
        for file_info in file_info_jsls:
            path_list_str += u'"' + file_info['path'] + u'",'

        path_list_str = path_list_str[:-1]
        path_list_str += u']'

        return share_id, share_uk, path_list_str

    def transfer_url(self, url_bdy, path_t_save):
        try:
            print(u"发送连接请求...")
            share_id, share_uk, path_list = self.get_file_info(url_bdy)
        except:
            print(u"链接失效了，没有获取到fileinfo...")
        else:
            error_code = self.transfer(share_id, share_uk, path_list, path_t_save)
            if error_code == 0:
                print(u"转存成功！")
            else:
                print(u"转存失败了，错误代码：" + str(error_code))


bduss = 'pMZW5ocy1lRXpzd0h0WmFSbzNVN0l4eXNPSlgtMFcyU1ROSTlBVEh1QktkSXRiQVFBQUFBJCQAAAAAAAAAAAEAAACbuU0HaGVyb7bLAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAErnY1tK52NbRU'
stoken = '321f9844d7b104194488ff67d7c403faa2e1f4ed5d825ea6e9a99f89a5c9b783'
bdstoken = "68b586b7c93e879a17a99e240f458b20"
bdy_trans = BaiduYunTransfer(bduss, stoken, bdstoken)

url_src = "https://pan.baidu.com/s/1KbFFbCvLoiMoavt_pLT9Ig"
path = u"/我的资源"

bdy_trans.transfer_url(url_src, path)
