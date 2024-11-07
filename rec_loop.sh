#!/bin/bash

# Launch stream in loop.
#

TStream=/home/luvwahraan/TwitchStream
NPLAY=$TStream/data/now_playing
LOCK_FILE=${TStream}/data/roon_np.lock
NB=${TStream}/data/count.np

NIMG=${TStream}/data/background.jpg
BG_DIR=${TStream}/backgrounds

echo 1 > $LOCK_FILE
echo -e "0\n0" > $NB

trap "echo 0 > $LOCK_FILE ; exit 0" \
  HUP INT QUIT EXIT KILL TERM #1 2 3 9 15

CRASHED=0
while [ $(head -n1 $LOCK_FILE) -eq 1 ] ; do
  echo -n "Crash: ${CRASHED}"
  
  UPDATED=$(head -n1 $NB)
  echo -e "${UPDATED}\n${CRASHED}" > $NB

  # Change background
  cp ${BG_DIR}/$(ls "${BG_DIR}" | sort -R | tail -n1) ${NIMG}
  
  ${TStream}/stream.py -d "${TStream}" --stream --verbose
  CRASHED=$(( $CRACHED + 1 ))
  sleep 1
done
