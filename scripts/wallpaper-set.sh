#!/usr/bin/env bash
# Use the maintained awww daemon for transitions when installed. Keep swww as a
# compatibility path for existing systems; swaybg is the required static fallback.

set -u
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPER="${1:-}"

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    printf 'Wallpaper file not found: %s\n' "$WALLPAPER" >&2
    exit 1
fi

mkdir -p "$CONFIG_DIR/dotfiles"

WALLPAPER_CMD=""
DAEMON_CMD=""
if command -v awww >/dev/null 2>&1 && command -v awww-daemon >/dev/null 2>&1; then
    WALLPAPER_CMD=awww
    DAEMON_CMD=awww-daemon
    pkill -u "$UID" -x swww-daemon 2>/dev/null || true
elif command -v swww >/dev/null 2>&1 && command -v swww-daemon >/dev/null 2>&1; then
    WALLPAPER_CMD=swww
    DAEMON_CMD=swww-daemon
fi

if [[ -n "$WALLPAPER_CMD" ]]; then
    if ! pgrep -u "$UID" -x "$DAEMON_CMD" >/dev/null 2>&1; then
        "$DAEMON_CMD" >/dev/null 2>&1 &
    fi
    for _ in {1..30}; do
        if "$WALLPAPER_CMD" query >/dev/null 2>&1; then
            break
        fi
        sleep 0.1
    done
    if "$WALLPAPER_CMD" img "$WALLPAPER" --transition-type grow --transition-pos 0.5,0.5 \
        --transition-fps 60 --transition-step 90 --transition-duration 1.5 >/dev/null 2>&1; then
        pkill -u "$UID" -x swaybg 2>/dev/null || true
        printf '%s\n' "$WALLPAPER" > "$CONFIG_DIR/dotfiles/current_wallpaper"
        exit 0
    fi
fi

if command -v swaybg >/dev/null 2>&1; then
    pkill -u "$UID" -x swaybg 2>/dev/null || true
    swaybg -i "$WALLPAPER" -m fill >/dev/null 2>&1 &
    printf '%s\n' "$WALLPAPER" > "$CONFIG_DIR/dotfiles/current_wallpaper"
    exit 0
fi

printf 'Install swaybg to display wallpapers.\n' >&2
exit 1
