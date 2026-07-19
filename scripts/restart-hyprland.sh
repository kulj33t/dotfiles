#!/usr/bin/env bash


echo "Reloading Hyprland..."


hyprctl reload


echo "Restarting Waybar..."

pkill waybar || true

waybar &


echo "Restart complete."
