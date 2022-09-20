#! /bin/bash
SOURCE=${BASH_SOURCE[0]}
LOC=$(dirname $(realpath  $SOURCE))
CONFIG=$LOC/rc.lua

echo "Started Xephyer on :1"
Xephyr -br -ac -noreset -screen 1400x900 :1 &
XEPHYER_PID=$!
DISPLAY=:1

echo "Waiting for X Display - $DISPLAY to go live ..."
while ! xset q &>/dev/null; do
sleep 0.1
done
echo "Xephyr live on $DISPLAY PID=$XEPHYER_PID"

echo "Starting awesome on $DISPLAY using: $CONFIG"
echo
awesome -c ~/Packages/KwesomeDE/rc.lua
echo
echo "awesome exitied - killing Xephyer:"
kill $XEPHYER_PID
echo "DONE"