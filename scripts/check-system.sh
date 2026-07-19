#!/usr/bin/env bash

PROGRAMS=(
    hyprland
    hyprctl
    kitty
    waybar
    wofi
    swaync
    swaylock
    fastfetch
    copyq
    pipewire
    bluetoothctl
)


echo "Checking installed programs..."
echo


for PROGRAM in "${PROGRAMS[@]}"
do

    if command -v "$PROGRAM" >/dev/null 2>&1
    then
        echo "[OK] $PROGRAM"
    else
        echo "[MISSING] $PROGRAM"
    fi

done
