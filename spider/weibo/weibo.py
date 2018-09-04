import requests
import json
import pandas as pd
import time

comment_parameter = []  #  用来存放weibo_id值
comment_url = []  #  用来存放weibo_url

# 获取每条微博的id值

url = 'https://m.weibo.cn/api/container/getIndex?uid=1773294041&luicode=10000011&lfid=100103' \
      'type%3D1%26q%3D%E7%8E%8B%E8%8F%8A&\featurecode=20000320&' \
      'type=uid&value=1773294041&containerid=1076031773294041'

c_r = requests.get(url)

for i in range(2, 9):
    c_parameter = (json.loads(c_r.text)["data"]["cards"][i]["mblog"]["id"])
    comment_parameter.append(c_parameter)

# 获取每条微博评论url
c_url_base = 'https://m.weibo.cn/api/comments/show?id='

for parameter in comment_parameter:
    for page in range(1, 101):  # 提前知道每条微博只可抓取前100页评论
        c_url = c_url_base + str(parameter) + "&page=" + str(page)
        comment_url.append(c_url)


user_id = []  # 用来存放user_id
comment = []  # 用来存放comment

i = 0
for url in comment_url:
    i = i + 1
    u_c_r = requests.get(url)
    try:
        for m in range(0, 9):  # 提前知道每个url会包含9条用户信息
            one_id = json.loads(u_c_r.text)["data"]["data"][m]["user"]["id"]
            user_id.append(one_id)
            one_comment = json.loads(u_c_r.text)["data"]["data"][m]["text"]
            comment.append(one_comment)
            print('success' + str(i))
    except:
        print('error' + str(i))
        pass

containerid = []
user_base_url = "https://m.weibo.cn/api/container/getIndex?type=uid&value="

for id in set(user_id):  #需要对user_id去重
    containerid_url = user_base_url + str(id)
    try:
        con_r = requests.get(containerid_url)
        one_containerid = json.loads(con_r.text)["data"]['tabsInfo']['tabs'][0]["containerid"]
        containerid.append(one_containerid)
    except:
        containerid.append(0)


feature = []  # 存放用户基本信息
id_lose = []  # 存放请求失败id
user_agent = "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"
headers = {"User-Agent": user_agent}
cookies = {"_T_WM": "fc75d89b71ce4104ecdfebf0a70c1b90",
           "M_WEIBOCN_PARAMS": "featurecode=20000320&luicode=20000174&lfid=102803&uicode=20000174",
           "MLOGIN": "1",
           "SCF": "AqKkH60ckq1T8Z6xh_h3bRiIJlffDnqk5FGAZU0_MXtVNe5WNTu6Cx2qihumhLSwAfFeRoCBaRuy48zxLfu9tgA.",
           "SSOLoginState": "1535613197",
           "SUB": "_2A252g-lcDeRhGedJ6VsV9ifNyj2IHXVVj_cUrDV6PUJbkdANLUTWkW1NVi9PDmVu1QsQsp5erJ3QAyO9-qTkrb0s",
           "SUHB": "0z1xnjU0HKpwFj",
           "TMPTOKEN": "49R7iaFBcpMfpQTJQ9SWWzspKroWqB72nCVV1eLRm0Y6jJLoeIwhw5CGABfAFXFQ",
           "WEIBOCN_FROM": "1110006030"}

m = 1

for num in zip(user_id,containerid):
    url = "https://m.weibo.cn/api/container/getIndex?uid="+str(num[0])+"&luicode=10000011&lfid=100103type%3D1%26q%3D&featurecode=20000320&type=uid&value="+str(num[0])+"&containerid="+str(num[1])
    try:
        r = requests.get(url, headers = headers, cookies = cookies)
        feature.append(json.loads(r.text)["data"]["cards"][1]["card_group"][1]["item_content"].split("  "))
        #feature.append(json.loads(r.text)["data"]["cards"][1])
        print("成功第{}条".format(m))
        m = m + 1
        time.sleep(1)  # 设置睡眠一秒钟，防止被封
    except:
        id_lose.append(num[0])

# 将featrue建立成DataFrame结构便于后续分析
user_info = pd.DataFrame(feature, columns = ["性别", "年龄", "星座", "国家城市"])
print (user_info)


user_info1 = user_info[(user_info["性别"] == "男") | (user_info["性别"] == "女")]  #去除掉性别不为男女的部分
user_info1 = user_info1.reindex(range(0,5212))  #重置索引
user_index1 = user_info1[(user_info1["国家城市"].isnull() == True)&(user_info1["星座"].isnull() == False)
                         &(user_info1["星座"].map(lambda s:str(s).find("座")) == -1)].index

for index in user_index1:
    user_info1.iloc[index, 3] = user_info1.iloc[index, 2]
user_index2 = user_info1[((user_info1["国家城市"].isnull() == True)&(user_info1["星座"].isnull() == True)
                          &(user_info1["年龄"].isnull() == False)&(user_info1["年龄"].map(lambda s:str(s).find("岁")) == -1))].index

for index in user_index2:
    user_info1.iloc[index, 3] = user_info1.iloc[index, 1]
user_index3 = user_info1[((user_info1["星座"].map(lambda s:str(s).find("座")) == -1)&
                          (user_info1["年龄"].map(lambda s:str(s).find("座")) != -1))].index

for index in user_index3:
    user_info1.iloc[index, 2] = user_info1.iloc[index, 1]
user_index4 = user_info1[(user_info1["星座"].map(lambda s:str(s).find("座")) == -1)].index

for index in user_index4:
    user_info1.iloc[index, 2] = "未知"
user_index5 = user_info1[(user_info1["年龄"].map(lambda s:str(s).find("岁")) == -1)].index

for index in user_index5:
    user_info1.iloc[index, 1] = "999岁"  #  便于后续统一处理
user_index6 = user_info1[(user_info1["国家城市"].isnull() == True)].index

for index in user_index6:
    user_info1.iloc[index, 3] = "其他"

print(user_info1)




#  因留言结构比较乱，所以先保存到本地做进一步处理
#  删除掉一些html元素
pd.DataFrame(comment).to_csv(r"C:\Users\nwgq2jchen1\Desktop\comment.csv")


user_info1["性别"].value_counts(normalize = True).plot.pie(title = "菊粉男女分布",autopct='%.2f')
#将把年龄从字符串变成数字
user_info1["age_1"] = [int(age[:-1]) for age in user_info1["年龄"]]
#对年龄进行分组
bins = (0,10,20,25,30,100,1000)#将年龄进行区间切分
cut_bins = pd.cut(user_info1["age_1"],bins = bins,labels = False)
ax = cut_bins[cut_bins < 5].value_counts(normalize =True).plot.bar(title = "菊粉年龄分布")#将大于100岁的过滤掉
ax.set_xticklabels(["0-10岁","10-20岁","20-25岁","25-30岁","30+"],rotation = 0)



#导入相关库

import matplotlib.pyplot as plt
import matplotlib
from matplotlib.patches import Polygon
from mpl_toolkits.basemap import Basemap
from matplotlib.collections import PatchCollection

#将省份和城市进行分列
country_data = pd.DataFrame([country.split(" ") for country in user_info1["国家城市"]],columns = ["省份","城市"])

#将国家和城市与user表合并
user_data = pd.merge(user_info1,country_data,left_index = True,right_index = True,how = "left")

#按省份进行分组计数
shengfen_data = user_data.groupby("省份")["性别"].count().reset_index().rename(columns = {"性别":"人次"})

#需要先对各省份地址进行经纬度解析

#导入解析好的省份经纬度信息

location = pd.read_table(r"C:\Users\zhangjunhong\Desktop\latlon_106318.txt",sep = ",")

#将省份数据和经纬度进行匹配

location_data = pd.merge(shengfen_data,location[["关键词","地址","谷歌地图纬度","谷歌地图经度"]],
                    left_on = "省份",right_on = "关键词",how = "left")

#进行地图可视化
#创建坐标轴

fig = plt.figure(figsize=(16,12))
ax  = fig.add_subplot(111)

#需要提前下载中国省份地图的.shp

#指明.shp所在路径进行导入
basemap = Basemap(llcrnrlon= 75,llcrnrlat=0,urcrnrlon=150,urcrnrlat=55,projection='poly',lon_0 = 116.65,lat_0 = 40.02,ax = ax)
basemap.readshapefile(shapefile = "C:/Users/zhangjunhong/Desktop/CHN_adm/CHN_adm1",name = "china")

#定义绘图函数

def create_great_points(data):
    lon   = np.array(data["谷歌地图经度"])
    lat   = np.array(data["谷歌地图纬度"])
    pop   = np.array(data["人次"],dtype=float)
    name = np.array(data["地址"])
    x,y = basemap(lon,lat)
    for lon,lat,pop,name in zip(x,y,pop,name):
        basemap.scatter(lon,lat,c = "#778899",marker = "o",s = pop*10)
        plt.text(lon,lat,name,fontsize=10,color = "#DC143C")

#在location_data上调用绘图函数

create_great_points(location_data)
plt.axis("off")#关闭坐标轴

plt.savefig("C:/Users/zhangjunhong/Desktop/itwechat.png")#保存图表到本地

plt.show()#显示图表

import squarify

# 创建数据

xingzuo = user_info1["星座"].value_counts(normalize = True).index
size = user_info1["星座"].value_counts(normalize = True).values
rate = np.array(["34%","6.93%","5.85%","5.70%","5.62%","5.31%","5.30%","5.24%","5.01%","4.78%","4.68%","4.36%"])

# 绘图

colors = ['steelblue','#9999ff','red','indianred',
          'green','yellow','orange']

plot = squarify.plot(sizes = size, # 指定绘图数据
                     label = xingzuo, # 指定标签
                     color = colors, # 指定自定义颜色
                     alpha = 0.6, # 指定透明度
                     value = rate, # 添加数值标签
                     edgecolor = 'white', # 设置边界框为白色
                     linewidth =3 # 设置边框宽度为3
                    )

# 设置标签大小

plt.rc('font', size=10)
# 设置标题大小
plt.title('菊粉星座分布',fontdict = {'fontsize':12})
# 去除坐标轴
plt.axis('off')
# 去除上边框和右边框刻度

plt.tick_params(top = 'off', right = 'off')

image = Image.open('C:/Users/zhangjunhong/Desktop/图片1.png')#作为背景形状的图
graph = np.array(image)

#参数分别是指定字体、背景颜色、最大的词的大小、使用给定图作为背景形状

wc = WordCloud(font_path = "C:\\Windows\\Fonts\\simkai.ttf", background_color = 'White', max_words = 150, mask = graph)

name = ["女性","摩羯座","20岁","21岁","22岁","23岁","24岁","25岁","广州","杭州","成都","武汉","长沙","上海","北京","海外","美国","深圳"]

value = [20,20,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10]#词的频率
dic = dict(zip(name, value))#词频以字典形式存储
wc.generate_from_frequencies(dic)#根据给定词频生成词云
image_color = ImageColorGenerator(graph)
plt.imshow(wc)
plt.axis("off")#不显示坐标轴
plt.show()
wc.to_file('C:/Users/zhangjunhong/Desktop/wordcloud.jpg')
