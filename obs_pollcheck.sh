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

ARCH=$2
OBS_LOC=$1

if [ -z $ARCH ]; then
       ARCH=x86_64
fi

while ! osc r $OBS_LOC -a $ARCH | grep -q -e "succeeded" -e "failed" -e "unresolvable"
do
    echo "Polling ($c)..."
    ((c++)) && ((c==40)) && c=0 && break
    sleep 30
done

RET=`osc r $OBS_LOC -a $ARCH | awk '{print $NF}'`

if [ -z $RET ]; then
	echo "ret=timed_out" >> $GITHUB_OUTPUT
	exit
fi

case $RET in
  "succeeded")
    echo "ret=success" >> $GITHUB_OUTPUT
    exit
    ;;

  "failed")
    echo "ret=failure" >> $GITHUB_OUTPUT
    exit
    ;;

  "unresolvable")
    echo "ret=failure" >> $GITHUB_OUTPUT
    exit
    ;;

  *)
    echo "ret=timed_out" >> $GITHUB_OUTPUT
    ;;
esac
