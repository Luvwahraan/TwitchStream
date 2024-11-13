#!/bin/bash

# Prepare stream data, then launch stream loops.
#

RES_W=1920
RES_H=1080

RES_W=1280
RES_H=720

echo "Set dirs"

BASE_DIR=/home/luvwahraan/TwitchStream

DISK=${BASE_DIR}/data
RP=${DISK}/roon_playing
NP=${DISK}/now.playing
LOCK_FILE=${DISK}/roon_np.lock

#BG=${BASE_DIR}/backgrounds
BG=${DISK}/backgrounds
IMG=${DISK}/background.jpg

echo "Moving to ${BASE_DIR}"
cd "${BASE_DIR}"

echo "Killing:"
for pid_file in $(ls data | grep -E 'pid$') ; do
  echo -e "\t${pid_file}"
  kill -9 $(cat "data/${pid_file}")
done
read

# Resize backgrounds
backgroundHandle() {
  echo "Background handle"
  # Check repertory, and empty it
  if [ ! -d "${BG}" ] ; then
  echo "Creating ${BG}"
    mkdir "${BG}"
  else
    rm "${BG}/"*
  fi
  
  # Resize all images
  echo "Resizing:"
  for img in $(ls backgrounds) ; do
    #cp -fR "backgrounds/${img}" "${BG}/${img}" # for now copy
    2>/dev/null 1>&2 ffmpeg -i "backgrounds/${img}" -vf scale="${RES_W}x${RES_H}" "${BG}/${img}"
    echo -e "\t${img}"
  done
}

choose_background() {
  NIMG=$(ls "${BG}" | sort -R | tail -n1)
  echo "Copy a random stream background."
  echo -e "\t${NIMG}"
  cat "${BG}/${NIMG}" > "${IMG}"
}

backgroundHandle
choose_background
read

ROON=/usr/local/Ropon
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
echo '' > "${NP}"
touch "${RP}"
read

echo "Alsa loopback"
alsaloop_pid=$(ps x | sed -nr '/alsaloop/ { /sed|SCREEN/! { s/ +/ /g ; s/([0-9]+) .*/\1/ ; p} }')
if [ -n "$alsaloop_pid" ] ; then
  echo -e "\tLoopback found '${alsaloop_pid}'"
else
  echo -e "\tNo loopback  '${alsaloop_pid}'"
  screen -dmS alsaloop alsaloop -r 48000 -C hw:0 -P hw:0 -l 256 -s 0 -U
  alsaloop_pid=$(ps x | sed -nr '/alsaloop/ { /sed|SCREEN/! { s/ +/ /g ; s/([0-9]+) .*/\1/ ; p} }')
fi
echo "${alsaloop_pid}" > "${DISK}/loopback.pid"

read

echo "Roon playback."
roon -z 'Roon Server' -c play

echo "Roon now playing data."
#kill -9 $(cat ${BASE_DIR}/data/now_playing.pid)
screen -dmS np ${BASE_DIR}/rn_loop.sh "${BASE_DIR}"

echo "ffmpeg stream"
screen -dmS stream ${BASE_DIR}/rec_loop.sh "${BASE_DIR}" "${RES_W}" "${RES_H}"

screen -ls
