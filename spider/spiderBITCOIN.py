# Code based on Python 3.x
# _*_ coding: utf-8 _*_
# __Author: "LEMON"
import csv
import time
from datetime import datetime

import pymongo
import requests
from bs4 import BeautifulSoup

import fire


client = pymongo.MongoClient('localhost')
db = client['BITCOIN']

def download(url):
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36'}
    response = requests.get(url, headers=headers)
    return response.text


def get_content(html):
    # 记录保存日期
    date = datetime.now().date()
    date = datetime.strftime(date, '%Y-%m-%d')  # 转变成str

    soup = BeautifulSoup(html, 'lxml')
    soup.prettify()
    body = soup.body
    data_main = body.find('div', {'class': 'boxContain'})

    if data_main:
        tables = data_main.find_all('tr')

        for i, table_info in enumerate(tables):
            if i == 0:
                continue

            tds = table_info.find_all('td')
            listid = tds[0].get_text()
            name = tds[1].get_text(strip=True)
            流通市值 = tds[2].get_text()
            价格 = tds[3].get_text()
            流通数量 = tds[4].get_text()
            流通率 = tds[5].get_text()
            成交额24H = tds[6].get_text()
            涨幅1h = tds[7].get_text (strip=True)
            涨幅24h = tds[8].get_text (strip=True)
            涨幅7D = tds[9].get_text (strip=True)
            detail = 'www.feixiaohao.com'+ tds[1].find('a').get('href')
            # 招聘简介


            # 用生成器获取信息
            yield {'listid': listid,
                   'name': name,
                   '流通市值': 流通市值,
                   '价格': 价格,
                   '流通数量': 流通数量,
                   '流通率': 流通率,
                   '成交额24H': 成交额24H,
                   '涨幅1h': 涨幅1h,
                   '涨幅24h': 涨幅24h,
                   '涨幅7D': 涨幅7D,
                   'detail': detail,
                   'Date':date
                   }


def main():
    basic_url = 'http://www.feixiaohao.com/all'

        # print(url)
    html = download(basic_url)
        # print(html)
    if html:
        mongo_table = db['BITCOIN']
        data = get_content(html)
        for item in data:
            if mongo_table.update({'name': item['name']}, {'$set': item}, True):
                print('已保存记录：', item)

if __name__ == '__main__':
    start = time.time()
    main()
    end = time.time()
    print('Finished, task runs %s seconds.' % (end - start))



#mongoexport.exe --csv -f name,listid,流通市值,价格,流通数量,流通率,成交额24H,涨幅1h,涨幅24h,涨幅7D,detail,Date -d BITCOIN -c BITCOIN -o ./test.csv



