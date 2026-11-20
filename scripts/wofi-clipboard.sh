#!/usr/bin/env bash
set -u

for tool in cliphist wl-copy wofi; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        command -v notify-send >/dev/null 2>&1 && notify-send -a Clipboard "Clipboard history unavailable" "Missing command: $tool" || true
        exit 1
    fi
done

SELECTED=$(cliphist list | wofi --show dmenu --prompt "Clipboard History" --location 0 --cache-file /dev/null)
[[ -n "$SELECTED" ]] || exit 0
printf '%s\n' "$SELECTED" | cliphist decode | wl-copy
