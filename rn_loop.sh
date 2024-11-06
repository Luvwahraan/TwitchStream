#!/bin/bash

# Room now playing loop
#

TStream=/home/luvwahraan/TwitchStream
Disk=${TStream}

RP=${Disk}/roon_playing
NP=${Disk}/now_playing

LOCK_FILE=${Disk}/roon_np.lock

trap "echo 0 > $LOCK_FILE ; echo '' > $NP ; exit 0" \
      HUP INT QUIT EXIT KILL TERM #1 2 3 9 15

echo 1 > "$LOCK_FILE"
while [ $(head -n1 $LOCK_FILE) -eq 1 ] ; do
  echo -n '.'

  ${TStream}/roon_now.sh 'Roon Server' "${TStream}"
  /usr/bin/sleep 10
done
