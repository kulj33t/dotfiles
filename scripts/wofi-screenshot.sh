#!/usr/bin/env bash
set -u

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILENAME="screenshot-$(date +'%Y-%m-%d-%H-%M-%S').png"
FULLPATH="$DIR/$FILENAME"

OPT_FULL="󰹑  Full Screen"
OPT_WINDOW="󰒉  Active Window"
OPT_SELECT="󰩬  Select Area"
CHOICE=$(printf '%s\n' "$OPT_FULL" "$OPT_WINDOW" "$OPT_SELECT" | \
    wofi --show dmenu --prompt "Screenshot" --location 0 --cache-file /dev/null)

notify_saved() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a Screenshot "$1" "$FILENAME" -i "$FULLPATH" 2>/dev/null || true
}
copy_image() {
    [[ -s "$FULLPATH" ]] && wl-copy --type image/png < "$FULLPATH"
}

case "$CHOICE" in
    "$OPT_FULL")
        sleep 0.4
        grim "$FULLPATH" && copy_image && notify_saved "Full screen captured"
        ;;
    "$OPT_WINDOW")
        ACTIVE=$(hyprctl activewindow -j 2>/dev/null || true)
        GEOMETRY=$(jq -r 'select(.size[0] > 0 and .size[1] > 0) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' <<< "$ACTIVE")
        if [[ -n "$GEOMETRY" ]]; then
            sleep 0.4
            grim -g "$GEOMETRY" "$FULLPATH" && copy_image && notify_saved "Window captured"
        else
            command -v notify-send >/dev/null 2>&1 && notify-send -a Screenshot "No active window" "Open a window and try again." || true
        fi
        ;;
    "$OPT_SELECT")
        GEOMETRY=$(slurp 2>/dev/null || true)
        if [[ -n "$GEOMETRY" ]] && grim -g "$GEOMETRY" "$FULLPATH"; then
            if command -v swappy >/dev/null 2>&1; then
                swappy -f "$FULLPATH"
            else
                copy_image
                notify_saved "Region captured"
            fi
        fi
        ;;
esac
