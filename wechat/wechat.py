#!/usr/bin/env python
# -*- coding:utf-8 -*-
#http://mp.weixin.qq.com/s?__biz=MzAxMjUyNDQ5OA==&mid=2653553234&idx=1&sn=73045e4a154f3d40a3640184d5c91c1e&chksm=806e2cefb719a5f97c88c97e3b34b2620e29a509e94857858f13db7e2ca2e58d2b7237cca800&scene=21#wechat_redirect

import itchat
import re
import jieba
import time

def echart_pie(friends):
    total = len(friends) - 1
    male = female = other = 0

    for friend in friends[1:]:
        sex = friend["Sex"]
        if sex == 1:
            male += 1
        elif sex == 2:
            female += 1
        else:
            other += 1

    total = len(friends[1:])  # 好了，打印结果
    print(u"男性好友：%.2f%%" % (float(male) / total * 100))
    print(u"女性好友：%.2f%%" % (float(female) / total * 100))
    print(u"其他：%.2f%%" % (float(other) / total * 100))
    
    # from echarts import Echart, Legend, Pie
    # chart = Echart('%s persentage' % (friends[0]['NickName']), 'from WeChat')
    # chart.use(Pie('WeChat',
    #               [{'value': male, 'name': 'male %.2f%%' % (float(male) / total * 100)},
    #                {'value': female, 'name': 'female %.2f%%' % (float(female) / total * 100)},
    #                {'value': other, 'name': 'other %.2f%%' % (float(other) / total * 100)}],
    #               radius=["50%", "70%"]))
    # chart.use(Legend(["male", "female", "other"]))
    # del chart.json["xAxis"]
    # del chart.json["yAxis"]
    # chart.plot()


def word_cloud(friends):
    import matplotlib.pyplot as plt
    from wordcloud import WordCloud, ImageColorGenerator
    import PIL.Image as Image
    import os
    import numpy as np
    d = os.path.dirname(__file__)
    my_coloring = np.array(Image.open(os.path.join(d, "5.png")))
    signature_list = []
    for friend in friends:
        signature = friend["Signature"].strip()
        signature = re.sub("<span.*>", "", signature)
        signature_list.append(signature)
    raw_signature_string = ''.join(signature_list)
    text = jieba.cut(raw_signature_string, cut_all=True)
    target_signatur_string = ' '.join(text)

    my_wordcloud = WordCloud(background_color="white", max_words=2000, mask=my_coloring, scale=2,
                             max_font_size=40, random_state=42,
                             font_path=r"C:\Windows\Fonts\simhei.ttf").generate(target_signatur_string)
    image_colors = ImageColorGenerator(my_coloring)
    plt.imshow(my_wordcloud.recolor(color_func=image_colors))
    plt.imshow(my_wordcloud)
    plt.axis("off")
    plt.show()
    # 保存图片 并发送到手机
    my_wordcloud.to_file(os.path.join(d, "wechat_cloud.png"))
    itchat.send_image("wechat_cloud.png", 'filehelper')

    
if __name__ == '__main__':

    itchat.auto_login(hotReload=True)
    itchat.dump_login_status()
    friends = itchat.get_friends(update=True)[:]
    # echart_pie(friends)
    word_cloud(friends)
