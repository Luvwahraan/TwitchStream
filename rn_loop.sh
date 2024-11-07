#!/bin/bash

# Room now playing loop
#

TStream=/home/luvwahraan/TwitchStream
Disk=${TStream}/data

RP=${Disk}/roon_playing
NP=${Disk}/now.playing
NP=${Disk}/last.np
NB=${Disk}/count.np

WAIT=10

LOCK_FILE=${Disk}/roon_np.lock
PID=''

trap "echo 0 > $LOCK_FILE ; echo '' > $NP ; kill $PID ; exit 0" \
      HUP INT QUIT EXIT KILL TERM #1 2 3 9 15

counter() {
  i=0
  while [ $(head -n1 $LOCK_FILE) -eq 1 ] ; do
    echo $i > $NB
    i=$(( $i + 1 ))
    sleep 1
  done
}


echo 1 > "$LOCK_FILE"
LAST_PID=0
while [ $(head -n1 $LOCK_FILE) -eq 1 ] ; do
  echo -n '.'

  ${TStream}/roon_now.sh 'Roon Server' "${TStream}"

  # Kill last counter, and start a new one.
  kill $PID
  counter &
  PID=$!

  sleep ${WAIT}
done
