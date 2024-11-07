#!/bin/bash

# Room now playing loop
#

TStream=/home/luvwahraan/TwitchStream
Disk=${TStream}/data

RP=${Disk}/roon_playing
NP=${Disk}/now.playing
NP=${Disk}/last.np
NB=${Disk}/count.np

LOCK_FILE=${Disk}/roon_np.lock
echo 1 > "$LOCK_FILE"

STREAM_CRASH=$(tail -n1 $NB)
WAIT=10

PID=''

trap "echo 0 > $LOCK_FILE ; echo '' > $NP ; kill $PID ; exit 0" \
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

  ${TStream}/roon_now.sh 'Roon Server' "${TStream}"

  # Kill last counter
  kill $PID
  
  # Update stream crashed count
  STREAM_CRASH=$(tail -n1 $NB)
  
  # Start a new last updated counter.
  counter &
  PID=$!

  sleep ${WAIT}
done
