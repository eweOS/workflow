#!/bin/bash

LANG=C
DATA="[]"
DATA_ITEM="{}"
STATE=0

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
}<<<$(pacman -Syi)
DATA=`echo $DATA | jq ". + [ $DATA_ITEM ]"`

echo $DATA | jq > pkgs.json
