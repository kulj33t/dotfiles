#!/usr/bin/env bash
# Find a keyboard LED entry without changing Waybar config on desktop systems.

set -u
DEVICE=""
for entry in /sys/class/leds/*; do
    [[ -e "$entry" ]] || continue
    name=$(basename "$entry")
    if [[ "$name" =~ [Kk][Bb][Dd] || "$name" =~ [Kk]eyboard ]]; then
        DEVICE="$name"
        break
    fi
done

if [[ -z "$DEVICE" ]] || ! command -v brightnessctl >/dev/null 2>&1; then
    printf '{"text":"","class":"hidden","tooltip":"No keyboard backlight found"}\n'
    exit 0
fi

PERCENT=$(brightnessctl -d "$DEVICE" -m 2>/dev/null | cut -d, -f4 | tr -d '%')
PERCENT=${PERCENT:-0}

if [[ "${1:-}" == toggle ]]; then
    if (( PERCENT <= 5 )); then
        brightnessctl -q -d "$DEVICE" set 10%
    elif (( PERCENT <= 15 )); then
        brightnessctl -q -d "$DEVICE" set 50%
    elif (( PERCENT <= 60 )); then
        brightnessctl -q -d "$DEVICE" set 100%
    else
        brightnessctl -q -d "$DEVICE" set 0%
    fi
    exit 0
fi

if (( PERCENT <= 5 )); then
    printf '{"text":"","class":"zero","tooltip":"Keyboard backlight: Off"}\n'
elif (( PERCENT <= 15 )); then
    printf '{"text":"","class":"low","tooltip":"Keyboard backlight: 10%%"}\n'
elif (( PERCENT <= 60 )); then
    printf '{"text":"","class":"half","tooltip":"Keyboard backlight: 50%%"}\n'
else
    printf '{"text":"","class":"full","tooltip":"Keyboard backlight: 100%%"}\n'
fi
