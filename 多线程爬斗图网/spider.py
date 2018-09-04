import  requests
import  threading

import time
from bs4 import BeautifulSoup
from lxml import etree

def get_html(url):
    #url='https://www.doutula.com/article/list/?page=1'

    headers = {'User-Agent':'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36'}   #可以在Chrome的network tab 里查看
    print(url)
    request = requests.get(url=url,headers=headers)
    response = request.content
    return response


def get_img_html(html):
    soup = BeautifulSoup(html,'lxml')

    classpath = ['list-group-item random_list tg-article','list-group-item','list-group-item random_list']
    # all_a = soup.find_all('a',class_='list-group-item random_list tg-article')
    # all_b = soup.find_all ('a', class_='list-group-item')
    # all_c = soup.find_all ('a', class_='list-group-item random_list')
    all_a = soup.find_all('a',class_=classpath)   #class 是python 的关键字  所以用class_代替 html里面的class 属性
    for link in all_a:
        img_html = get_html(link['href'])
        img_html += img_html

    return  img_html


def get_img(html):

    soup = etree.HTML(html)
    items = soup.xpath('//div[@class="artile_des"]')

    for item in items:
        imgurl_list = item.xpath('table/tbody/tr/td/a/img/@onerror')    #img 的 onerror属性
        start_save_img(imgurl_list)

def save_img(img_url):
    img_url = img_url.split('=')[-1][1:-2].replace('jp','jpg')   # [-1][1:-2] python的切片
    if img_url[0:4] == 'http':
        print (u'正在下载' +  img_url)
        img_content = requests.get(img_url).content
    else:
        print (u'正在下载' + 'http:' + img_url)
        img_content = requests.get('http:'+img_url).content
    with open('G:\doutu\%s.jpg' % img_url.split('/')[-1],'wb') as f:    #  %s 传入参数
        f.write(img_content)


def start_save_img(imgurl_list):
    for i in imgurl_list:

        thread_list = []
        if len (thread_list) < 12:
            th = threading.Thread (target=save_img, args=(i,))    #  args = (i,)  是个元祖
            th.setDaemon (True)
            th.start ()
            thread_list.append (th)
            break
        else:
            print ('线程数为:' + str (len (thread_list)) + '等待清空')
            time.sleep (1)
            for thread in thread_list:
                if not thread.is_alive ():
                    thread_list.remove (thread)



def main():
    start_url = 'https://www.doutula.com/article/list/?page={}'
    for i in range(1,5):
        start_html = get_html(start_url.format(i))
        print(start_html)
        html = get_img_html(start_html)
        get_img(html)

main()
print('爬虫结束')