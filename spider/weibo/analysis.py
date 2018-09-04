import pandas as pd
import fool
import numpy as np
import matplotlib.pyplot as plt
from collections import Counter
from PIL import Image, ImageSequence
from wordcloud import WordCloud, ImageColorGenerator


comment_data = pd.read_excel(r"C:\Users\nwgq2jchen1\Desktop\comment.xlsx")
#  将数据转换成字符串
text = (",").join(comment_data[0]).replace('[', '').replace(']', '').replace('【','').replace('】','').replace('.', '')

#  进行分词
cut_text = fool.cut(text)
flat = lambda L: sum(map(flat,L),[]) if isinstance(L,list) else [L]
ol = flat(cut_text) # output:['1', '2', '3', '4', '5', '6', '7', '8']
print(ol)
print(' '.join(ol))
#cut_text = ' '.join(fool.cut(text))

#  将分词结果进行计数

c = Counter(ol)

c.most_common(500)  #挑选出词频最高的500词

#  将结果导出到本地进行再一次清洗,删除无意义的符号词

#pd.DataFrame(c.most_common(500)).to_csv(r"C:\Users\nwgq2jchen1\Desktop\fenci.csv")
# 导入背景图，这里选择菊姐头像
image = Image.open('C:/Users/nwgq2jchen1/Desktop/db-logo.png')
#将 图片信息转换成数组形式
graph = np.array(image)
#设置词云参数
#参数分别是指定字体、背景颜色、最大的词的大小、使用给定图作为背景形状
wc = WordCloud(font_path = "C:\\Windows\\Fonts\\simkai.ttf", background_color = 'White', max_words = 150, mask = graph)
fp = pd.read_csv(r"C:\Users\nwgq2jchen1\Desktop\fenci.csv", encoding = "utf-8")#读取词频文件
name = list(fp.name)#词
value = fp.time#词的频率
dic = dict(zip(name, value))#词以及词频以字典形式存储
#根据给定词频生成词云
wc.generate_from_frequencies(dic)
image_color = ImageColorGenerator(graph)
plt.imshow(wc)
plt.axis("off")#不显示坐标轴
plt.show()
#保存结果到本地
wc.to_file('C:/Users/nwgq2jchen1/Desktop/wordcloud.jpg')