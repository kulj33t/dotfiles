#!/usr/bin/env bash
# Prepare a cached, softened copy of the active wallpaper for GTKLock/swaylock.

set -u

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
wallpaper="${1:-}"

if [[ -z "$wallpaper" && -r "$CONFIG_DIR/dotfiles/current_wallpaper" ]]; then
    IFS= read -r wallpaper < "$CONFIG_DIR/dotfiles/current_wallpaper" || true
fi

if [[ -z "$wallpaper" || ! -f "$wallpaper" ]]; then
    exit 1
fi

if command -v magick >/dev/null 2>&1; then
    image_tool=(magick)
elif command -v convert >/dev/null 2>&1; then
    image_tool=(convert)
else
    # Keep the wallpaper consistent if ImageMagick was unavailable or skipped.
    printf '%s\n' "$wallpaper"
    exit 0
fi

cache_dir="$CACHE_HOME/dotfiles"
background="$cache_dir/lock-wallpaper.png"
metadata="$cache_dir/lock-wallpaper.source"
cache_revision='gtklock-blur-v2'
mkdir -p "$cache_dir" || exit 1
chmod 700 "$cache_dir" 2>/dev/null || true

if source_stamp="$(stat -c '%y:%s' -- "$wallpaper" 2>/dev/null)"; then
    :
elif source_stamp="$(stat -f '%m:%z' "$wallpaper" 2>/dev/null)"; then
    :
else
    source_stamp="unknown"
fi

if [[ -s "$background" && -f "$metadata" ]] && \
    printf '%s\n%s\n%s\n' "$wallpaper" "$source_stamp" "$cache_revision" | \
        cmp -s - "$metadata"; then
    printf '%s\n' "$background"
    exit 0
fi

temporary_background="$cache_dir/.lock-wallpaper.$$.png"
temporary_metadata="$cache_dir/.lock-wallpaper.$$.source"
trap 'rm -f "$temporary_background" "$temporary_metadata"' EXIT

if ! "${image_tool[@]}" "$wallpaper" -auto-orient -resize '2560x2560>' \
    -blur 0x32 -brightness-contrast '-12x0' -strip "PNG:$temporary_background"; then
    printf '%s\n' "$wallpaper"
    exit 0
fi

if [[ ! -s "$temporary_background" ]]; then
    printf '%s\n' "$wallpaper"
    exit 0
fi

printf '%s\n%s\n%s\n' "$wallpaper" "$source_stamp" "$cache_revision" > "$temporary_metadata" || {
    printf '%s\n' "$wallpaper"
    exit 0
}
mv -f "$temporary_background" "$background" || {
    printf '%s\n' "$wallpaper"
    exit 0
}
mv -f "$temporary_metadata" "$metadata" || {
    printf '%s\n' "$wallpaper"
    exit 0
}

printf '%s\n' "$background"
