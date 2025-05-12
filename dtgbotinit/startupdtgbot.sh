#!/bin/bash

mkdir -p /data/logs

# pause a little to give domoticz time to start
sleep 2

# turn on bash's job control
set -m

# Start the web monitor/config process
bash /dtgbotinit/startupwebserver.sh >> /data/logs/dtgbot_webserver.log 2>&1 &

# Start the dtgbot process
cd /dtgbot
lua /dtgbot/dtgbot__main.lua
exit_code=$?

# Handle specific exit codes
if [ $exit_code -eq 0 ]; then
    echo "Lua script exited successfully."
    exit 1
elif [ $exit_code -eq 1 ]; then
    echo "Lua script requesting Restart."
    exit 1
elif [ $exit_code -eq 99 ]; then
    echo "Process stopped because it's missing configuration information. Check the log for details."
    exit 0
elif [ $exit_code -eq 143 ]; then
    echo "Lua Forced Restart by kill task via Web Update Config."
    exit 1
else
    echo "Lua script encountered a critical error $exit_code. Stopping container."
    exit 0
fi

# debugging
#sleep 3600