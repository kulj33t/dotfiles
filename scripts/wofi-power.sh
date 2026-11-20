#!/usr/bin/env bash
set -u

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
OPT_LOCK="  Lock Session"
OPT_SUSPEND="  Suspend System"
OPT_REBOOT="  Reboot System"
OPT_SHUTDOWN="  Power Off"
OPT_LOGOUT="  Exit Hyprland"

CHOICE=$(printf '%s\n' "$OPT_LOCK" "$OPT_SUSPEND" "$OPT_REBOOT" "$OPT_SHUTDOWN" "$OPT_LOGOUT" | \
    wofi --show dmenu --prompt "Power Menu" --location 0 --cache-file /dev/null)

case "$CHOICE" in
    "$OPT_LOCK") bash "$CONFIG_DIR/scripts/lock.sh" ;;
    "$OPT_SUSPEND") loginctl suspend ;;
    "$OPT_REBOOT") loginctl reboot ;;
    "$OPT_SHUTDOWN") loginctl poweroff ;;
    "$OPT_LOGOUT") hyprctl dispatch exit ;;
esac
