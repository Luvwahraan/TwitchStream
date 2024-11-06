#!/usr/bin/env python3

"""
Generate ffmpeg command with filters, and options for twitch
"""

import os
import datetime

DIR = None
DIR = str(sys.argv[1])

endl = " \\\n   "

RES = '1920x1080'

KEY_FILE = f"{DIR}/twitch.key"
NPLAY = f"{DIR}/data/now.playing"
IMG = f"{DIR}/data/background.jpg"

NP_FONT = f"{DIR}/fonts/font_np.otf"
NP_STYLE = f"fontcolor=white :fontsize=58 :box=1 :boxcolor=black@0.6 :boxborderw=25"
NP_POS = f"x=(w-text_w)/2 :y=(h-text_h)-15" # centered at 5px from bottom


T_FONT = f"{DIR}/fonts/font_t.ttf"
T_STYLE = f"fontcolor=white :fontsize=90 :box=1 :boxcolor=black@0.6 :boxborderw=5"
T_POS = f"x=(w-text_w)/2 :y=5" # centered at 5px from top
T_OPTS = f"{NP_FONT} :textfile={NPLAY} :reload=1 :{NP_STYLE} :{NP_POS}"

def stream_log( msg:str ):
  with open(f"{DIR}/data/stream.log", 'a') as logfile:
    logfile.write( f"{datetime.datetime.now()} > {msg" )

TWITCH_KEY = None
with open(KEY_FILE, 'r') as keyFile:
    TWITCH_KEY = keyFile.readline()
if TWITCH_KEY == '' or TWITCH_KEY == None:
    raise Exception( f"No twitch key in '{KEY_FILE}'" )
TWITCH_URL = f"rtmp://live.twitch.tv/app/{TWITCH_KEY}"


command = '/usr/bin/ffmpeg ' #-report '
inputData = [
    f"-loop 1 -i {IMG}",
    '-f alsa -ac 2 -i hw:1,1 -c:a aac -b:a 320k'
    #'-f jack -ac 2 -i directStream -c:a aac -b:a 320k',
  ]
filters = [
    # audio waves
    f"[1:a]showwaves=s={RES} :mode=line,colorkey=black[waves]",
    '[bg][waves]overlay=format=rgb[v1]',

    # now playing
    f"[v1]drawtext={T_OPTS},format=rgba[np]",
    '[v1][np]overlay=format=rgb[v2]',

    # local time
    f"[v2]drawtext={T_FONT} :text='%"+'{localtime\\:%T}'+f"' :{T_STYLE} :{T_POS}[t]",
    '[v2][t]overlay=format=rgb[v3]',
  ]

options = [
    '-c:v libx264 -preset faster -b:v 1600k',
    '-x264opts keyint=60 -r 30 -pix_fmt yuv420p',
  ]

maps = [
  '[v3]', # overlays
  '1:a',  # audio
]

outputData = f"-f flv {TWITCH_URL}"
#outputData = f"{DIR}/data/output.mp4"

complete_process = command + endl

if len(inputData) > 0:
  complete_process += endl.join(inputData) + endl


if len(filters) > 0:
  complete_process += '-filter_complex "' + f" ;{endl}   ".join(filters) + '" '+endl

if len(options) > 0:
  complete_process += endl.join(options) + endl

for stream in maps:
  complete_process += f"-map {stream} "


complete_process += endl + outputData

print( complete_process + "\n\n" )

stream_log('ffmpg starts')
os.system( complete_process )
stream_log('ffmpg stops')
