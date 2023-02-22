#! /bin/bash
SOURCE=${BASH_SOURCE[0]}
LOC=$(realpath "$(dirname $(realpath $SOURCE))/..")
echo $LOC
CONFIG=$LOC/rc.lua

# Save the current session so persistent won't try to restore some previous session
# sleep enough time so it actually saves to disk
awesome-client 'require("daemons.system.persistent"):save()'
sleep 1.5

echo "Started Xephyer on :1"
Xephyr -br -ac -noreset -screen 1280x600 :1 &
XEPHYER_PID=$!
DISPLAY=:1

echo "Waiting for X Display - $DISPLAY to go live ..."
while ! xset q &>/dev/null; do
sleep 0.1
done
echo "Xephyr live on $DISPLAY PID=$XEPHYER_PID"

echo "Starting awesome on $DISPLAY using: $CONFIG"
echo
awesome -c $LOC/rc-debug.lua
echo
echo "awesome exitied - killing Xephyer:"
kill $XEPHYER_PID
echo "DONE"