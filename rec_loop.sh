#!/bin/bash

# Launch stream in loop.
#

BASE_DIR=/home/luvwahraan/TwitchStream
NPLAY=$BASE_DIR/data/now_playing
LOCK_FILE=${BASE_DIR}/data/roon_np.lock
NB=${BASE_DIR}/data/count.np

NIMG=${BASE_DIR}/data/background.jpg
BG_DIR=${BASE_DIR}/backgrounds

echo 1 > $LOCK_FILE
echo -e "0\n0" > $NB

trap "echo 0 > $LOCK_FILE ; exit 0" \
  HUP INT QUIT EXIT KILL TERM #1 2 3 9 15

CRASHED=0
while [ $(head -n1 $LOCK_FILE) -eq 1 ] ; do
  echo -n "Crash: ${CRASHED}"
  
  UPDATED=$(head -n1 $NB)
  echo -e "${UPDATED}\n${CRASHED}" > $NB

  # Change stream background with a random one.
  cp ${BG_DIR}/$(ls "${BG_DIR}" | sort -R | tail -n1) ${NIMG}
  
  ${BASE_DIR}/stream.py -d "${BASE_DIR}" --stream --verbose
  CRASHED=$(( $CRACHED + 1 ))
  sleep 1
done
