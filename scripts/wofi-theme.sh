#!/usr/bin/env bash
set -u

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
THEMES_DIR="$CONFIG_DIR/themes"
if [[ ! -d "$THEMES_DIR" ]]; then
    printf 'Theme directory is missing: %s\n' "$THEMES_DIR" >&2
    exit 1
fi

mapfile -t THEMES < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
(( ${#THEMES[@]} > 0 )) || exit 0
SELECTED=$(printf '%s\n' "${THEMES[@]}" | wofi --show dmenu --prompt "Select Theme" --location 0 --cache-file /dev/null)
[[ -n "$SELECTED" ]] && bash "$CONFIG_DIR/scripts/theme-switch.sh" "$SELECTED"
