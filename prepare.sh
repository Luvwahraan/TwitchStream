#!/bin/bash

# Prepare stream data, then launch stream loops.
#


BASE_DIR=/home/luvwahraan/TwitchStream

DISK=${BASE_DIR}/data
RP=${DISK}/roon_playing
NP=${DISK}/now.playing
LOCK_FILE=${DISK}/roon_np.lock

BG=${BASE_DIR}/backgrounds
NIMG=${DISK}/background.jpg

echo "Copy a random stream background."
cp ${BG}/$(ls "${BG}" | sort -R | tail -n1) ${NIMG}

ROON=/usr/local/Roon
ROONAPI=${ROON}/api
ROONETC=${ROON}/etc
ROONCONF=${ROONETC}/pyroonconf
NOWP=now_playing.py

# Use a Python virtual environment
[ -f ${ROON}/venv/bin/activate ] && source ${ROON}/venv/bin/activate
[[ ":$PATH:" == *":/usr/local/Roon/venv/bin:"* ]] || {
  export PATH=/usr/local/Roon/venv/bin:${PATH}
}

echo "Reset counters."
echo '' > ${NP}
touch ${RP}

echo "Alsa loopback"
screen -dmS alsaloop alsaloop -r 48000 -C hw:0 -P hw:0 -l 256 -s 0 -U
echo $! > ${DISK}/loopback.pid

echo "Roon playback."
roon -z 'Roon Server' -c play

echo "Roon now playing data."
screen -dmS ${BASE_DIR}/rn_loop.sh
echo $! > ${DISK}/now_playing.pid

echo "ffmpeg stream"
screen -dmS ${BASE_DIR}/rec_loop.sh
echo $! > ${DISK}/stream.pid
