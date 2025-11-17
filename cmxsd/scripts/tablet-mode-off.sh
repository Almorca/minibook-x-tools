#!/bin/bash
# 
# Hyprland tablet mode deactivation script
# This script is executed when the device exits tablet mode
#
# Default actions for Hyprland desktop mode restoration

#set -euo pipefail

# Log tablet mode deactivation
logger "Tablet mode deactivated"

KBD="wvkbd-deskintl"
KBD_PID=$(pgrep -u "$USER" -x "$KBD")

if [[ ! -z "$KBD_PID" ]]; then
    echo "Hiding $KBD..."
    kill -USR1 "$KBD_PID"
    echo "Hid $KBD - $KBD_PID"
else
    echo "$KBD was not running."
fi

# Optional: Send notification
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Laptop Mode" "Device switched to laptop mode" --icon=input-keyboard 2>/dev/null || true
fi

logger "Laptop mode script completed"
