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

if osc rmkpac --scmsync "https://github.com/eweOS/packages#$BRANCH_NAME" eweOS:Main $BRANCH_NAME \
	| grep -q 'already exists'; then
	echo "Creation failed, package exists."
	exit 1
fi
