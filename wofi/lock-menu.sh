#!/bin/bash

OPT_LOCK=" Lock"
OPT_LOGOUT=" Logout"
OPT_SUSPEND=" Suspend"
OPT_HIBERNATE=" Hibernate"
OPT_REBOOT=" Reboot"
OPT_SHUTDOWN=" Shutdown"

CHOICE=$(echo -e "${OPT_LOCK}\n${OPT_SUSPEND}\n${OPT_HIBERNATE}\n${OPT_LOGOUT}\n${OPT_REBOOT}\n${OPT_SHUTDOWN}" | wofi --show dmenu --prompt "Power Menu" --location 0 --cache-file /dev/null)

case "$CHOICE" in
    "$OPT_LOCK")
        swaylock
        ;;
    "$OPT_LOGOUT")
        hyprctl dispatch exit
        ;;
    "$OPT_SUSPEND")
        systemctl suspend
        ;;
    "$OPT_HIBERNATE")
        systemctl hibernate
        ;;
    "$OPT_REBOOT")
        systemctl reboot
        ;;
    "$OPT_SHUTDOWN")
        systemctl poweroff
        ;;
esac
