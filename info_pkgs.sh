#!/bin/bash

LANG=C
DATA="[]"
DATA_ITEM="{}"
STATE=0

mkdir -p results

{
read
read
read
while read -r;
do
        if [ -z "$REPLY" ]; then
                STATE=0
                DATA=`echo $DATA | jq ". + [ $DATA_ITEM ]"`
                DATA_ITEM="{}"
        else
                if [[ "$STATE" == 0 ]]; then
                        STATE=1
                fi
                K=$(echo $REPLY | cut -d ':' -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                V=$(echo $REPLY | cut -d ':' -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/\"/\'/g")
                if [[ "$K" == "Name" ]]; then
                        echo $V
                fi
                DATA_ITEM=`echo $DATA_ITEM | jq ". + {\"$K\":\"$V\"}"`
        fi
done
}<<<$(pacman -Syyi)
DATA=`echo $DATA | jq ". + [ $DATA_ITEM ]"`

echo $DATA | jq > results/_pkgs.json
for repo in $(jq -cr '.[] | .Repository' results/_pkgs.json | uniq | xargs); do
  mkdir results/$repo
done
pushd results
jq -cr '.[] | .Repository + "/" + .Name, .' _pkgs.json | awk 'NR%2{f=$0".json";next} {print >f;close(f)}'
popd
jq -cr '[.[] | {Name,Version,Repository}]' results/_pkgs.json > results/_pkgs_brief.json
