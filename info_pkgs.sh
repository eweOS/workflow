#!/bin/bash

LANG=C
DATA_ITEM="{}"
STATE=0

pacman -Syy

mkdir -p results

function extract_info(){

pkgname=$1
echo "Extracting $pkgname"
mkdir -p $(dirname results/$pkgname.json)

{
while read -r;
do
        if [ -z "$REPLY" ]; then
                STATE=0
                DATA_ITEM="{}"
        else
                if [[ "$STATE" == 0 ]]; then
                        STATE=1
                fi
                K=$(echo $REPLY | cut -d ':' -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                V=$(echo $REPLY | cut -d ':' -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/\"/\'/g")
                DATA_ITEM=$(echo $DATA_ITEM | jq ". + {\"$K\":\"$V\"}")
        fi
done
}<<<$(pacman -Sii $pkgname)

echo $DATA_ITEM > results/$pkgname.json
}

{
while read -r;
do
        extract_info $REPLY &
        [ $( jobs | wc -l ) -ge $( nproc ) ] && wait
done
}<<<$(pacman -Sl | cut -f1-2 -d ' ' | sed 's/ /\//')

find results -type f -name "*.json" | xargs -I @ cat @ | jq -s '. | [.[] | {Name,Version,Repository}]' > results/_pkgs_brief.json
