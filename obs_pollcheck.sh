#!/bin/bash

cd /tmp

mkdir -p ~/.config/osc/
cat <<EOF > ~/.config/osc/oscrc
[general]
apiurl = https://os-build.ewe.moe
[https://os-build.ewe.moe]
user=github
pass=$OSC_PASS
EOF

BRANCH_NAME=$1
PRID=$2
ARCH=$3
OBS_LOC=eweOS:PR/$PRID-$BRANCH_NAME

if [ -z $ARCH ]; then
	ARCH=x86_64
fi

osc r $OBS_LOC -a $ARCH
#timeout 1200 osc r $OBS_LOC -a $ARCH -w
#TIMEOUT=$?

#if [ $TIMEOUT -ne 0 ]; then
#	echo "timeout=1" >> $GITHUB_OUTPUT
#fi
