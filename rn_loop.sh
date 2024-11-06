#!/bin/bash

# Room now playing loop
#

TStream=/home/luvwahraan/TwitchStream
Disk=${TStream}/data

RP=${Disk}/roon_playing
NP=${Disk}/now.playing

WAIT=10

LOCK_FILE=${Disk}/roon_np.lock

trap "echo 0 > $LOCK_FILE ; echo '' > $NP ; exit 0" \
      HUP INT QUIT EXIT KILL TERM #1 2 3 9 15

echo 1 > "$LOCK_FILE"
while [ $(head -n1 $LOCK_FILE) -eq 1 ] ; do
  echo -n '.'

  ${TStream}/roon_now.sh 'Roon Server' "${TStream}"

  # Update last now playing checking
  for i in $(seq $WAIT) ; do
    LAST=$(head -n1 $NP | sed -r "s/([0-9]+)\+?s ago/\1/")
    LAST=$(( ${LAST} + 1 ))
    TEXT=$LAST

    if [ ${LAST} -gt $(( $WAIT - 2 )) ] ; then
      TEXT="${LAST}+"
    fi

    if [ ${LAST} -lt $WAIT ] ; then
      sed -r "s/([0-9]+\+?)(s ago)/${TEXT}\2/" $NP > $NP.1
      cat $NP.1 > $NP
    fi

    sleep 1
  done

done
