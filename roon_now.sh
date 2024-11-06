#!/bin/bash

# Get and format roon nom playing informations.
#

GROUP="$1"
DIR="$2"

TStream=${DIR}
RP=$TStream/data/roon_playing
NP=$TStream/data/now.playing
LP=$TStream/data/last.played
LOCK_FILE=$TStream/data/roon_np.lock


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


#NIMG=${TStream}/data/background.jpg
#BG=${TStream}/backgrounds
#IMG=
#cp ${BG}/$(ls "${BG}" | sort -R | tail -n1) ${NIMG}

roon -nz $GROUP | /usr/bin/sed -nr '/Track|Artist|Album/ { s/[\t ]+([A-Z][a-z]+:)[\t ]+(.*)/\1\2/ ; s/\n\t\t//g ; p }' > $RP

sed -nr '/Track/ { s/Track:(.*)/\1/ ;p }'  $NP > ${DIR}/data/track.np
sed -nr '/Artist/ { s/Artist:(.*)/\1/ ;p }'  $NP > ${DIR}/data/artist.np
sed -nr '/Album/ { s/Album:(.*)/\1/ ;p }'  $NP > ${DIR}/data/album.np

echo -e "1s ago" > $NP
#date +%T >> $NP
cat $RP >> $NP

/usr/bin/sleep 1
