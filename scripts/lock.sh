#!/usr/bin/env bash
# GTKLock provides the custom UI; swaylock is the fast, secure fallback.

set -u
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

if pgrep -u "$UID" -x gtklock >/dev/null 2>&1 || pgrep -u "$UID" -x swaylock >/dev/null 2>&1; then
    exit 0
fi

if command -v playerctl >/dev/null 2>&1; then
    playerctl pause >/dev/null 2>&1 || true
fi

if command -v gtklock >/dev/null 2>&1; then
    exec gtklock --daemonize --style "$CONFIG_DIR/gtklock/style.css"
elif command -v swaylock >/dev/null 2>&1; then
    exec swaylock --config "$CONFIG_DIR/swaylock/config" --daemonize
fi

command -v notify-send >/dev/null 2>&1 && notify-send -a dotFiles "No screen locker installed" "Install gtklock or swaylock." || true
exit 1
