#!/bin/bash
# Screen Rotation Script for Hyprland
# 
# This script is called by cmxsd when the device orientation changes.
# It receives the orientation name as a parameter and rotates the screen accordingly.
#
# Usage: rotate-screen.sh <orientation>
#   orientation: normal, right-up, left-up, bottom-up
#
# Configuration: Set NORMAL_TRANSFORM to match your device's natural normal orientation
# For DSI-1 on Chuwi Minibook X, the natural normal is transform 3 (270 degrees)

set -e

# Configuration
NORMAL_TRANSFORM=3  # For DSI-1 on Chuwi Minibook X (270 degrees)
                       # Adjust this based on your device (0-3)

# Get orientation parameter
ORIENTATION="$1"

if [ -z "$ORIENTATION" ]; then
    echo "Error: No orientation specified" >&2
    echo "Usage: $0 <orientation>" >&2
    exit 1
fi

# Get current monitor configuration (first monitor)
MONITOR_INFO=$(hyprctl monitors -j | jq -r '.[0]')

if [ -z "$MONITOR_INFO" ]; then
    echo "Error: Could not get monitor information" >&2
    exit 1
fi

# Extract monitor name and current settings
MONITOR_NAME=$(echo "$MONITOR_INFO" | jq -r '.name')
TOUCHSCREEN_NAME="goodix-capacitive-touchscreen-1"
WIDTH=$(echo "$MONITOR_INFO" | jq -r '.width')
HEIGHT=$(echo "$MONITOR_INFO" | jq -r '.height')
REFRESH=$(echo "$MONITOR_INFO" | jq -r '.refreshRate' | cut -d. -f1)
POS_X=$(echo "$MONITOR_INFO" | jq -r '.x')
POS_Y=$(echo "$MONITOR_INFO" | jq -r '.y')
SCALE=$(echo "$MONITOR_INFO" | jq -r '.scale')

# Map orientation to transform offset
# right-up  -> 90 degrees clockwise from normal  -> offset +1
# normal    -> natural normal                     -> offset  0
# left-up   -> 270 degrees clockwise from normal -> offset +3 (or -1)
# bottom-up -> 180 degrees from normal           -> offset +2

case "$ORIENTATION" in
    normal)
        OFFSET=0
        ;;
    right-up)
        OFFSET=3
        ;;
    bottom-up)
        OFFSET=2
        ;;
    left-up)
        OFFSET=1
        ;;
    *)
        echo "Warning: Unknown orientation '$ORIENTATION', defaulting to normal" >&2
        OFFSET=0
        ;;
esac

# Calculate final transform (wrap around at 4)
TRANSFORM=$(( (NORMAL_TRANSFORM + OFFSET) % 4 ))

# Apply the new monitor configuration
echo "Rotating $MONITOR_NAME to $ORIENTATION (transform $TRANSFORM)"
hyprctl keyword monitor "$MONITOR_NAME,${WIDTH}x${HEIGHT}@${REFRESH},${POS_X}x${POS_Y},$SCALE,transform,$TRANSFORM"
### NOTE: keyword paths are very very very tied to how one's hyprland config is setup.
###   If you have multiple touch devices, make sure to override transforms in each as appropriate.
###   This *has* to be the global setting, as of hyprland 0.52.1 and hyprlang 0.6.5
###   there seems to be no way to address devices by name.
hyprctl keyword input:touchdevice:transform "$TRANSFORM"

exit 0
