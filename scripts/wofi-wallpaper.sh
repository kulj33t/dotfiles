#!/usr/bin/env bash
set -u

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
THEMES_DIR="$CONFIG_DIR/themes"
mapfile -d '' -t WALLPAPERS < <(find "$THEMES_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print0 2>/dev/null | sort -z)

if (( ${#WALLPAPERS[@]} == 0 )); then
    command -v notify-send >/dev/null 2>&1 && notify-send -a Wallpaper "No wallpapers found" \
        "Add images under ${XDG_CONFIG_HOME:-$HOME/.config}/themes/<theme>/wallpapers/." || true
    exit 0
fi

LABELS=()
for path in "${WALLPAPERS[@]}"; do
    filename=$(basename "$path")
    theme=$(basename "$(dirname "$(dirname "$path")")")
    LABELS+=("$theme — $filename")
done

SELECTED=$(printf '%s\n' "${LABELS[@]}" | wofi --show dmenu --prompt "Select Wallpaper" --location 0 --cache-file /dev/null)
[[ -n "$SELECTED" ]] || exit 0

for index in "${!LABELS[@]}"; do
    if [[ "${LABELS[$index]}" == "$SELECTED" ]]; then
        "$CONFIG_DIR/scripts/wallpaper-set.sh" "${WALLPAPERS[$index]}"
        command -v notify-send >/dev/null 2>&1 && notify-send -a Wallpaper "Wallpaper updated" "$(basename "${WALLPAPERS[$index]}")" -i "${WALLPAPERS[$index]}" 2>/dev/null || true
        exit 0
    fi
done
