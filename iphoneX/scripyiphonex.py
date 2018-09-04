import time
import json
import re
import scrapy
import pymongo


def load_param():
    try:
        with open("/tmp/param") as f:
            content = f.read()
            data = json.loads(content)
            start = data.setdefault("start", 0)
            return start
    except:
        return 0

def save_param(start):
    with open("/tmp/param", "wb") as f:
        result = json.dumps({
            "start": start,
        })
        f.write(result)

class QuotesSprider(scrapy.Spider):
    name = "iphonex"
    url_patt = 'https://s.taobao.com/search?q=iphonex&imgfile=&commend=all&ssid=s5-e&search_type=item&sourceId=tb.index&spm=a21bo.2017.201856-taobao-item.2&ie=utf8&initiative_id=tbindexz_20170306&app=detailproduct&through=1'

    def start_requests(self):
        start = load_param()
        url = self.url_patt % (start)
        self.start = start
        yield scrapy.Request(url=url, callback=self.parse)

    def parse(self, response):
        content = response.body
        patt = r'jsonp\d+\((.*)\);'
        matched = re.search(patt, content, re.MULTILINE)
        data = json.loads(matched.group(1))
        items = data["mods"]["itemlist"]["data"]["auctions"]
        client = pymongo.MongoClient()
        db = client["iphonex"]
        print(items)
        new_items = db.items.insert_many(items)
        self.start = self.start + 44
        save_param(self.start)
        url = self.url_patt % (self.start)
        time.sleep(2)
        yield scrapy.Request(url=url, callback=self.parse)

start_requests()

    # def get_iphonex(self):
    #     client = pymongo.MongoClient()
    #     db = client["iphonex"]
    #     items = db["items"]
    #     prices = []
    #     sales = []
    #     com_counts = []
    #     urls = []
    #     titles = []
    #     nids = []
    #
    #     for item in items.find():
    #         title = item["raw_title"]
    #         if (re.search(r"iphonex", title, re.I) or \
    #             re.search(r"iphone x", title, re.I)) and \
    #             not re.search(r"iphone 8", title, re.I) and \
    #             not re.search(r"iphone8", title, re.I):
    #             titles.append(title)
    #         else:
    #             continue
    #
    #         nids.append(item["nid"])
    #         url = item["detail_url"]
    #         urls.append(url)
    #         view_price = item.setdefault("view_price", "0")
    #         prices.append(float(view_price))
    #         comment_count = 0
    #         if "comment_count" in item and item["comment_count"]:
    #             comment_count = int(item["comment_count"])
    #         com_counts.append(comment_count)
    #         view_sales = item.setdefault("view_sales", "0")
    #         matched = re.match(r'(\d+)', view_sales)
    #         if matched:
    #             view_sales_num = matched.group(1)
    #             sales.append(int(view_sales_num))
    #         else:
    #             sales.append(-1)
    #     pd.set_option('display.max_colwidth', -1)



