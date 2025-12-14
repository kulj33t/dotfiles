#!/bin/bash

SCREENSHOT_DIR="$HOME/screenshots"
TIMESTAMP="$(date +'%Y-%m-%d-%H-%M-%S')"
FILENAME="screenshot-${TIMESTAMP}.png"

if [[ ! -d "$SCREENSHOT_DIR" ]]; then
    mkdir -p "$SCREENSHOT_DIR"
fi

OPT_FULL="Full Screen"
OPT_SELECT="Select Area"

CHOICE=$(echo -e "${OPT_FULL}\n${OPT_SELECT}" | wofi --show dmenu --prompt "Screenshot" --location 0 --cache-file /dev/null)

case "$CHOICE" in
    "$OPT_FULL")
        sleep 0.5
        grim "${SCREENSHOT_DIR}/${FILENAME}"
        ;;
    "$OPT_SELECT")
        grim -g "$(slurp)" "${SCREENSHOT_DIR}/${FILENAME}"
        ;;
esac
