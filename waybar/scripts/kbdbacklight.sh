#!/bin/bash

# Device Name
DEVICE="kbd_backlight"

# Get current percentage directly
PERCENT=$(brightnessctl -d $DEVICE -m | cut -d, -f4 | tr -d %)

# --- TOGGLE MODE ---
if [ "$1" == "toggle" ]; then
    if [ "$PERCENT" -le 5 ]; then
        # 0% -> 10%
        brightnessctl -d $DEVICE set 10%
    elif [ "$PERCENT" -le 15 ]; then
        # 10% -> 50%
        brightnessctl -d $DEVICE set 50%
    elif [ "$PERCENT" -le 60 ]; then
        # 50% -> 100%
        brightnessctl -d $DEVICE set 100%
    else
        # 100% -> 0%
        brightnessctl -d $DEVICE set 0%
    fi
    exit
fi

# --- STATUS MODE ---
if [ "$PERCENT" -le 5 ]; then
    echo '{"text": "", "class": "zero", "tooltip": "Keyboard: Off"}'
elif [ "$PERCENT" -le 15 ]; then
    echo '{"text": "", "class": "low", "tooltip": "Keyboard: 10%"}'
elif [ "$PERCENT" -le 60 ]; then
    echo '{"text": "", "class": "half", "tooltip": "Keyboard: 50%"}'
else
    echo '{"text": "", "class": "full", "tooltip": "Keyboard: 100%"}'
fi
