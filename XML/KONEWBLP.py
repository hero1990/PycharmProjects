import xml.etree.ElementTree as ET
import os
import sys


# 遍历xml文件
def traverseXml(element):
    # print (len(element))
    if len(element) > 0:
        for child in element:
            print(child.tag, "----", child.attrib)
            traverseXml(child)
            # else:
            # print (element.tag, "----", element.attrib)


if __name__ == "__main__":
    xmlFilePath = os.path.abspath("SHPORD_20181016073248051.xml")
    print(xmlFilePath)
    try:
        tree = ET.parse(xmlFilePath)
        # 获得根节点
        root = tree.getroot()
    except Exception as e:  # 捕获除与程序退出sys.exit()相关之外的所有异常
        print("parse test.xml fail!")
        sys.exit()
    print(root.tag, "----", root.attrib)

    print(20 * "*")
    # 遍历xml文件
    traverseXml(root)
    print(20 * "*")

    for E1EDL37 in root[0][1].iter('E1EDL37'):
        for EXIDV in E1EDL37.findall('EXIDV'):
            print(EXIDV.text)
        for POSNR in E1EDL37.iter('POSNR'):
            print(POSNR.text)

    print(20 * "*")

