#!/usr/bin/env python3

"""
Generate ffmpeg command with filters, and options for twitch
"""

import argparse

parser = argparse.ArgumentParser(
  description='Generate ffmpeg command with filters and options for twitch.',
)

parser.add_argument(
    "-v",
    "--verbose",
    default=False,
    action="store_true",
    help="Print output in log and stdout."
)

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



KEY_FILE = f"{args.directory}/twitch.key"
NPLAY = f"{args.directory}/data/now.playing"
NCOUNT = f"{args.directory}/data/count.np"
IMG = f"{args.directory}/data/background.jpg"



import datetime
LOG = f"{args.directory}/data/stream.log"
def stream_log( msg:str ):
  with open(LOG, 'a') as logfile:
    logfile.write( f"{datetime.datetime.now()}\t{msg}\n" )

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

endl = " \\\n   "

RES = '1920x1080'

NP_FONT = f"{args.directory}/fonts/font_np.otf"
NP_STYLE = f"fontcolor=white :fontsize=58 :box=1 :boxw=1820 :boxcolor=black@0.6 :boxborderw=2|25"
#NP_POS = f"x=(w-text_w)/2 :y=(h-text_h)-15" # centered at 5px from bottom
NP_POS = f"x=50 :y=(h-th)-25" # centered at 5px from bottom
NP_OPTS = f"{NP_FONT} :textfile={NPLAY} :reload=1 :{NP_STYLE} :{NP_POS}"


T_FONT = f"{args.directory}/fonts/font_t.ttf"
T_STYLE = f"fontcolor=white :text_align=C :fontsize=130 :box=1 :boxw=1920 :boxcolor=black@0.6 :boxborderw=5"
T_POS = f"x=30 :y=15" # centered at 5px from top

filters = []
def genOverlays():
  vn = 2
  last = ''
  pos_count = 1
  for elem in ['track', 'artist', 'album']:
    print(f"Generating track overlay")
    
    file = f"{args.directory}/data/{elem}.np"
    vin_bg = f"v{vn}"
    text_bg = f"t{vn}"
    layout_bg = f"v{vn+1}"
    
    vin_fg = f"v{vn+1}"
    text_fg = f"t{vn+1}"
    layout_fg = f"v{vn+2}"
    
    border = 5
    style_bg = f"fontcolor=white :fontsize=58 :box=1 :boxw=1920 :boxcolor=black@0.6 :boxborderw={border}|25|{border}|110"
    style_fg = 'fontcolor=white :fontsize=58 :box=0'
    
    pos = f"y=860+({pos_count}*(41+{border*2}))"
    pos_bg = f"x=50 :{pos}"
    pos_fg = f"x=200 :{pos}"
    
    textout_bg = f"[{vin_bg}]drawtext={NP_FONT} :text={elem} :{style_bg} :{pos_bg},format=rgba[{text_bg}]"
    overlay_bg = f"[{vin_bg}][{text_bg}]overlay=format=rgb[{layout_bg}]"   
    filters.append(textout_bg)
    filters.append(overlay_bg)
    
    textout_fg = f"[{vin_fg}]drawtext={NP_FONT} :textfile={file} :reload=1 :{style_fg} :{pos_fg},format=rgba[{text_fg}]"
    overlay_fg = f"[{vin_fg}][{text_fg}]overlay=format=rgb[{layout_fg}]"
    filters.append(textout_fg)
    filters.append(overlay_fg)
    
    last = layout_fg
    vn = vn + 2
    pos_count += 1
  
  cnb_out = 'cnb'
  count_nb = f"[{last}]drawtext={NP_FONT} :textfile={NCOUNT} :reload=1 :fontcolor=white :fontsize=32 :box=0 :x=5:y=932,format=rgba[nb]"
  overlay = f"[{last}][nb]overlay=format=rgb[{cnb_out}]"
  filters.append(count_nb)
  filters.append(overlay)
  
  return cnb_out


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
    # local time
    f"[v1]drawtext={T_FONT} :text='%"+'{localtime\\:%T}'+f"' :{T_STYLE} :{T_POS}[t]",
    '[v1][t]overlay=format=rgb[v2]',

    # now playing
    #f"[v2]drawtext={NP_OPTS},format=rgba[np]",
    #'[v2][np]overlay=format=rgb[output]',
  ]
output = genOverlays()

options = [
    #'-c:v libx264 -preset faster -b:v 1600k',
    '-c:v libx264 -preset veryfast -b:v 1600k',
    '-x264opts keyint=60 -r 30 -pix_fmt yuv420p',
  ]

# Reduce verbosity
if not args.verbose: options.append('-loglevel 16')

maps = [
  f"[{output}]", # overlays
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
  import os
  stream_log('ffmpg starts')
  
  # Too much output to log if verbose, but print command.
  if args.verbose:
    print( complete_process )
    os.system( complete_process )
  else:
    os.system( f"echo >> {LOG} ; {complete_process} 2>> {LOG}" )

  stream_log('ffmpg stops')


