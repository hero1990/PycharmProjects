import sys
from pytube import YouTube

def main(link):
    link ='https://www.youtube.com/watch?v=xTlNMmZKwpA'
    yt = YouTube(link)
    video = yt.get('mp4', '1080p')
    video.download('D://youtube')

if __name__ == "__main__":
  #  main(sys.argv[1])

  main(123)