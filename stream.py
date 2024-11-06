#!/usr/bin/env python3

"""
Generate ffmpeg command with filters, and options for twitch
"""

import argparse

parser = argparse.ArgumentParser(
  description='Generate ffmpeg command with filters and options for twitch.',
)

#parser.add_argument(
#    "-v",
#    "--verbose",
#    default=False,
#    action="store_const",
#    help="Print output in log and stdout."
#)

parser.add_argument(
    "-d",
    "--directory",
    type=str,
    help='Twitch stream base directory, who contains background, fonts, scripts and data.'
)

parser.add_argument(
    "--dry-run",
    default=False,
    action="store_true",
    help="Generate ffmpeg command, without stream or write file."
)

parser.add_argument(
    "-s",
    "--stream",
    default=False,
    action="store_true",
    help="Launch Twitch stream. Can’t be used with --file option"
)
parser.add_argument(
    "-f",
    "--file",
    default=False,
    action="store_true",
    help="Record in file. Can't be used with --stream option."
)
args = parser.parse_args()


import datetime
LOG = f"{args.directory}/data/stream.log"
def stream_log( msg:str ):
  with open(LOG, 'a') as logfile:
    logfile.write( f"\n{datetime.datetime.now()}\t{msg}" )

if args.dry_run != False:
  print("Dry run mode.\n")

try:
  if not args.stream and not args.file:
    raise Exception('No stream or file output.')

  # Need only one.
  if args.stream and args.file:
    raise Exception('Please choose betwitch streaming (--stream) or recording (--file).')

except Exception as e:
  #stream_log( e.msg )
  print( e )
  exit(0)

import os

endl = " \\\n   "

RES = '1920x1080'

KEY_FILE = f"{args.directory}/twitch.key"
NPLAY = f"{args.directory}/data/now.playing"
IMG = f"{args.directory}/data/background.jpg"

NP_FONT = f"{args.directory}/fonts/font_np.otf"
NP_STYLE = f"fontcolor=white :fontsize=58 :box=1 :boxw=1820 :boxcolor=black@0.6 :boxborderw=25"
#NP_POS = f"x=(w-text_w)/2 :y=(h-text_h)-15" # centered at 5px from bottom
NP_POS = f"x=50 :y=(h-text_h)-15" # centered at 5px from bottom


T_FONT = f"{args.directory}/fonts/font_t.ttf"
T_STYLE = f"fontcolor=white :text_align=C :fontsize=130 :box=1 :boxw=1820 :boxcolor=black@0.6 :boxborderw=5"
T_POS = f"x=50 :y=15" # centered at 5px from top
T_OPTS = f"{NP_FONT} :textfile={NPLAY} :reload=1 :{NP_STYLE} :{NP_POS}"






TWITCH_KEY = 'rtmp://live.twitch.tv/app/'
# Don't load stream key if not necessary.
if args.stream:
  with open(KEY_FILE, 'r') as keyFile:
    # First line is key.
    TWITCH_KEY = TWITCH_KEY + keyFile.readline()

  if TWITCH_KEY == 'rtmp://live.twitch.tv/app/':
    raise Exception( f"No twitch key in '{KEY_FILE}'" )
  TWITCH_URL = f"rtmp://live.twitch.tv/app/{TWITCH_KEY}"
else:
  TWITCH_KEY = TWITCH_KEY + '<twitch key>'


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
    '-loglevel 16'
  ]

maps = [
  '[v3]', # overlays
  '1:a',  # audio
]

if args.file:
  outputData = f"{args.directory}/data/output.mp4"
elif args.stream:
  outputData = f"-f flv {TWITCH_URL}"

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


if args.dry_run:
  print( complete_process )
else:
  stream_log('ffmpg starts')
  os.system( f"echo >> {LOG} ; {complete_process} 2>> {LOG}" )
  stream_log('ffmpg stops')


