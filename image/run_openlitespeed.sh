#!/bin/bash

# Function to stop OpenLiteSpeed gracefully
shutdown() {
    # Log to syslog
    logger "Received daemon SIGTERM signal. Shutting down OpenLiteSpeed gracefully..."
    /usr/local/lsws/bin/lswsctrl stop
    logger "OpenLiteSpeed has been stopped."
    exit 0
}


# Trap SIGTERM
trap 'shutdown' SIGTERM

# Start OpenLiteSpeed
/usr/local/lsws/bin/lswsctrl start

# Keep script running, checking every 60 seconds if OpenLiteSpeed is still running
while true; do
    sleep 60
    if ! /usr/local/lsws/bin/lswsctrl status | grep 'litespeed is running with PID *' > /dev/null; then
        logger "OpenLiteSpeed stopped unexpectedly."
        exit 1
    fi
done
