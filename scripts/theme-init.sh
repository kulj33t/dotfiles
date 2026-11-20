#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
THEME="tokyo-night"
if [[ -s "$CONFIG_DIR/dotfiles/current_theme" ]]; then
    IFS= read -r THEME < "$CONFIG_DIR/dotfiles/current_theme" || true
fi

# Re-apply on every session start so the wallpaper backend is restored after login.
bash "$CONFIG_DIR/scripts/theme-switch.sh" "$THEME" "" --quiet
