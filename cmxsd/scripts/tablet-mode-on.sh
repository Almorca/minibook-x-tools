#!/bin/bash
# 
# Hyprland tablet mode activation script
# This script is executed when the device enters tablet mode
#
# Default actions for Hyprland tablet mode optimization

#set -euo pipefail

# Log tablet mode activation
logger "Tablet mode activated"

KBD="wvkbd-deskintl"
KBD_PID=$(pgrep -u "$USER" -x "$KBD")

if [[ -z "$KBD_PID" ]]; then
    echo "Starting $KBD..."
    "$KBD" &
    KBD_PID=$!   # PID of the process we just launched
    echo "Started with PID $KBD_PID"
else
    echo "Already running $KBD with PID $KBD_PID"
    kill -USR2 $KBD_PID
fi

# Optional: Send notification
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Tablet Mode" "Device switched to tablet mode" --icon=input-tablet 2>/dev/null || true
fi

logger "Tablet mode script completed"
