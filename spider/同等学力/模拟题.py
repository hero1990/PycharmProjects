# Code based on Python 3.x
# _*_ coding: utf-8 _*_
# __Author: "LEMON"

import time

import requests


def download(url, bduss, stoken, id ):
    headers = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Accept-Encoding': 'gzip, deflate',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Cache-Control': 'max-age=0',
        'Connection': 'keep-alive',
        'Cookie': 'CCKF_visitor_id_77418=1077773715; ASP.NET_SessionId=ykcofpgimmgc1cc0pnjilsz1; XX_UserId=7hjP52z3LxkA4fjkrslLZQGeFrGNl/pd/7I0BZ/8SOna3zV+S0iYGg==; XX_UserNo=tMeEuV91un8TN6S3p0Hswb9mbDlSg2H59ERlZchNW5L4nILr9QF+bQ==; XX_A_AllUserId=TWhrZduhs2U=; .ASPXAUTH=54065C3374DAEAF426C8A47F8E5729204C56DED898A9C59F23DB1339CD90B20F1603045751D539F22CD347D3F73D726DECC3275C3DC8F6F24FEF3C44B342F97A6AA9DA247F696B8949EC5E1B374614D8E69E29F8F580C2264435CE1F35FFD603247CF553B241C1A450B45D8556AAA7AEAFB743348C8772446CBD6C544E5C720DBC61984CF82B213F9D921D2B31364B0232C2514DAAB6D1BBAD1D9787F7560A2902C6EA5E89AC4B5F0676EAD408FD7E2FBE556EB0208E587ACF59D2AABB712A5D; DoQuestionDate=2018%2f5%2f21+20%3a17%3a49',
        'Host': 'usertk.100xuexi.com',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36'
    }
    response = requests.get(url, headers=headers)
    return response.text

if __name__ == '__main__':
    start = time.time()
    url = 'http://usertk.100xuexi.com/PracticeCenter/Examtest/Index?TQuestionPlanID=2622&GroupUserName=&code=&tb_l_PaperQuePlanID=63132&Model=chapter&TypeMenuFlag=23#'
    html = download(url, '7hjP52z3LxkA4fjkrslLZQGeFrGNl', 'tMeEuV91un8TN6S3p0Hswb9mbDlSg2H59ERlZchNW5L4nILr9QF', '1077773715')
    print(html)
    end = time.time()
    print('Finished, task runs %s seconds.' % (end - start))
