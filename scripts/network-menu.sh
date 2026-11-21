#!/usr/bin/env bash
set -u

if command -v nmtui >/dev/null 2>&1; then
    CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
    exec "$CONFIG_DIR/scripts/terminal-launch.sh" nmtui
elif command -v nm-connection-editor >/dev/null 2>&1; then
    exec nm-connection-editor
fi

if command -v notify-send >/dev/null 2>&1; then
    notify-send -a dotFiles "Network settings unavailable" \
        "Install NetworkManager with nmtui or nm-connection-editor to use this shortcut."
fi
exit 1
