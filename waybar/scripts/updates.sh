#!/bin/bash

CACHE_FILE="$HOME/.cache/waybar/updates.json"

if [ "$1" == "check" ]; then
    echo "{\"text\": \"...\", \"tooltip\": \"Checking...\", \"class\": \"pending\"}" > "$CACHE_FILE"
    pkill -SIGRTMIN+8 waybar

    count=$(dnf check-update --refresh -q | grep -v '^$' | wc -l)

    if [ "$count" -gt 0 ]; then
        json="{\"text\": \"$count\", \"tooltip\": \"$count updates available\", \"class\": \"pending\"}"
    else
        json="{\"text\": \"0\", \"tooltip\": \"System is up to date\", \"class\": \"updated\"}"
    fi

    echo "$json" > "$CACHE_FILE"
    pkill -SIGRTMIN+8 waybar
    exit 0
fi

if [ -f "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
else
    echo "{\"text\": \"0\", \"tooltip\": \"Click to check\", \"class\": \"updated\"}"
fi
