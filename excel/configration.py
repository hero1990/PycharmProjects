# !/usr/bin./python
# _*_coding:utf-8_*_
# python读取配置文件练习
import configparser

config = configparser.ConfigParser()    # 注意大小写
config.read("config.ini")   # 配置文件的路径
config.sections()
# #config.items('ODMCODE')

# print(config.sections())
# print(config.options('ODMCODE'))


condition = list(config.get('ODMCODE', 'condition').split(','))
print(condition)
odm = list(config.get('ODMCODE', 'odm').split(','))
print(odm)
reverse = config.get('ODMCODE', 'reverse')
print(reverse)

# ret_list = [item for item in odm if item not in condition]
retD = list(set(odm).difference(set(condition)))
print(retD)
# print(ret_list)

if reverse == 'false':
    condition = condition
    print('import ODM:', condition)
elif reverse == 'true':
    condition = retD
    print('import ODM:', condition)