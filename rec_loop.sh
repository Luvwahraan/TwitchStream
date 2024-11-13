#!/bin/bash

# Launch stream in loop.
#

BASE_DIR="$1"
RES_W="$2"
RES_H="$3"

#BASE_DIR=/home/luvwahraan/TwitchStream
NPLAY=$BASE_DIR/data/now_playing
LOCK_FILE=${BASE_DIR}/data/roon_np.lock
NB=${BASE_DIR}/data/count.np

SPID=${BASE_DIR}/data/stream.pid

LOG=${BASE_DIR}/data/stream.log

NIMG=${BASE_DIR}/data/background.jpg
BG_DIR=${BASE_DIR}/data/backgrounds


echo $$ > ${SPID}
echo 1 > $LOCK_FILE
echo -e "0\n0" > $NB

trap "echo 0 > $LOCK_FILE ; exit 0" \
  HUP INT QUIT EXIT KILL TERM #1 2 3 9 15

CRASHED=0
while [ $(head -n1 $LOCK_FILE) -eq 1 ] ; do

  # Change stream background with a random one.
  cp ${BG_DIR}/$(ls "${BG_DIR}" | sort -R | tail -n1) "${NIMG}"
  
  # STREAM START
  #
  ${BASE_DIR}/stream.py --stream \
      --directory "${BASE_DIR}" \
      --width "${RES_W}" --height "${RES_H}" \
      --verbose
  ###
  
  CRASHED=$(( $CRACHED + 1 ))
  echo "Crash grow to: ${CRASHED}"
  echo "Crash grow to: ${CRASHED}" >> ${LOG}
  
  # Kill rn_loop, to avoid concurrent writes on count.np
  kill -9 $(cat ${BASE_DIR}/data/now_playing.pid)
  
  UPDATED=$(head -n1 $NB)
  echo -e "${UPDATED}\n${CRASHED}" > $NB
  
  sleep 1
  
  # Restart killed rn_loop
  screen -dmS np ${BASE_DIR}/rn_loop.sh "${BASE_DIR}"
done
