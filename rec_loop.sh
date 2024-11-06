#!/bin/bash

# Launch stream in loop.
#

TStream=/home/luvwahraan/TwitchStream
NPLAY=$TStream/data/now_playing
LOCK_FILE=${TStream}/data/roon_np.lock

NIMG=${TStream}/data/background.jpg
BG_DIR=${TStream}/backgrounds

trap "echo 0 > $LOCK_FILE ; exit 0" \
  HUP INT QUIT EXIT KILL TERM #1 2 3 9 15


while [ $(head -n1 $LOCK_FILE) -eq 1 ] ; do
  echo -n '.'

  # Change background
  cp ${BG_DIR}/$(ls "${BG_DIR}" | sort -R | tail -n1) ${NIMG}
  
  ${TStream}/stream.py "${TStream}"
  sleep 1
done
