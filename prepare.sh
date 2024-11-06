#!/bin/bash

# Prepare stream data, then launch stream loops.
#


TStream=/home/luvwahraan/TwitchStream

Disk=${TStream}/data
RP=${Disk}/roon_playing
NP=${Disk}/now.playing
LOCK_FILE=${Disk}/roon_np.lock

BG=${TStream}/backgrounds
NIMG=${Disk}/background.jpg

cp ${BG}/$(ls "${BG}" | sort -R | tail -n1) ${NIMG}

ROON=/usr/local/Roon
ROONAPI=${ROON}/api
ROONETC=${ROON}/etc
ROONCONF=${ROONETC}/pyroonconf
NOWP=now_playing.py

#cd ${ROONAPI} || exit 1

# Use a Python virtual environment
[ -f ${ROON}/venv/bin/activate ] && source ${ROON}/venv/bin/activate
[[ ":$PATH:" == *":/usr/local/Roon/venv/bin:"* ]] || {
  export PATH=/usr/local/Roon/venv/bin:${PATH}
}

echo '' > ${NP}
touch ${RP}


screen -dmS ${TStream}/rn_loop.sh
screen -dmS ${TStream}/rec_loop.sh

