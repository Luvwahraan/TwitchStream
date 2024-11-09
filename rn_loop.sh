#!/bin/bash

# Room now playing loop
#

BASE_DIR="$1"

#BASE_DIR=/home/luvwahraan/TwitchStream
DISK=${BASE_DIR}/data

RP=${DISK}/roon_playing
NP=${DISK}/now.playing
NP=${DISK}/last.np
NB=${DISK}/count.np

SPID=${DISK}/now_playing.pid

LOCK_FILE=${DISK}/roon_np.lock
echo 1 > "$LOCK_FILE"

echo $$ > ${SPID}

STREAM_CRASH=$(tail -n1 $NB)
WAIT=10

PID=''

trap "kill -9 ${PID} ; echo '' > ${NP} ; echo '' > ${SPID} ; exit 0" \
      HUP INT QUIT EXIT KILL TERM #1 2 3 9 15

counter() {
  i=0
  while [ $(head -n1 $LOCK_FILE) -eq 1 ] ; do
    echo -e "$i\n${STREAM_CRASH}" > $NB
    i=$(( $i + 1 ))
    sleep 1
  done
}

LAST_PID=0
while [ $(head -n1 $LOCK_FILE) -eq 1 ] ; do
  echo -n '.'

  ${BASE_DIR}/roon_now.sh 'Roon Server' "${BASE_DIR}"

  # Kill last counter
  kill $PID
  
  # Update stream crashed count
  STREAM_CRASH=$(tail -n1 $NB)
  
  # Start a new last updated counter.
  counter &
  PID=$!

  sleep ${WAIT}
done
