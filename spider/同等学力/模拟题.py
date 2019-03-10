# Code based on Python 3.x
# _*_ coding: utf-8 _*_
# __Author: "LEMON"

import time

import requests


def download(url, bduss, stoken, id ):
    headers = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Accept-Encoding': 'gzip, deflate',
        'Accept-Language': 'en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7',
        'Cache-Control': 'max-age=0',
        'Connection': 'keep-alive',
        'Cookie': 'UM_distinctid=168a8db13b6123-0d26912327445c-b781636-100200-168a8db13b816d; NTKF_T2D_CLIENTID=guestEDCD3382-2DED-C75B-7FA4-A8DB152F16E4; XX_UserId=7hjP52z3LxkA4fjkrslLZQGeFrGNl/pd/7I0BZ/8SOna3zV+S0iYGg==; XX_UserNo=btLZVPzZRjkgqUu+Iw+8k9SsY8iQ9GJ9Qkf+1VypPMiRe19JVdHX6g==; XX_A_AllUserId=TWhrZduhs2U=; .ASPXAUTH=4C0A3091C880C8A0525C55C97D7CBB7ECBD9EAF8654AB952BAC17F2F359911104E80FF114C1E42DD343C9F1E16A0B2B15BF359859B90CE4B3D6EC2F0C11CC23D32212B6F5907FDABC33E8C8D3136651F9A7CEC8C817C5192E4F6F12337484C1AE3F7B546A9C534855ACA2E95E783FF2835D1897ECBCDE0702B73920550F97838BEE4467B914A3AA7F12712B71F7491EE037641AEDD5AC414E522CD378AC2E945BD47A3939D2A3C14723FF21CECDAED04841D8569F8554D6DFEFFF9142DFE1FBB; ASP.NET_SessionId=i2lahnotjqdmlmhprldlk2yo; DoQuestionDate=2019%2f2%2f1+20%3a16%3a18',
        'Host': 'usertk.100xuexi.com',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36'
    }
    response = requests.get(url, headers=headers)
    return response.text

if __name__ == '__main__':
    start = time.time()
    url = 'http://usertk.100xuexi.com/PracticeCenter/Examtest/Index?TQuestionPlanID=2622&GroupUserName=&code=&tb_l_PaperQuePlanID=63132&Model=chapter&TypeMenuFlag=23'
    html = download(url, '7hjP52z3LxkA4fjkrslLZQGeFrGNl/pd/7I0BZ/8SOna3zV+S0iYGg==', 'btLZVPzZRjkgqUu+Iw+8k9SsY8iQ9GJ9Qkf+1VypPMiRe19JVdHX6g==', '1077773715')
    print(html)
    end = time.time()
    print('Finished, task runs %s seconds.' % (end - start))
