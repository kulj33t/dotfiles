#!/usr/bin/env bash
# Apply a curated theme to the user's writable XDG config tree.

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
THEME="${1:-tokyo-night}"
REQUESTED_WALLPAPER="${2:-}"
QUIET="${3:-}"
SEED_ONLY="${4:-}"
THEMES_DIR="$CONFIG_DIR/themes"
if [[ ! -d "$THEMES_DIR" ]]; then
    THEMES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../themes" && pwd)"
fi

if [[ ! "$THEME" =~ ^[a-z0-9-]+$ || ! -d "$THEMES_DIR/$THEME" ]]; then
    printf 'Error: unknown theme: %s\n' "$THEME" >&2
    command -v notify-send >/dev/null 2>&1 && notify-send -a dotFiles "Theme switch failed" "Unknown theme: $THEME" || true
    exit 1
fi

THEME_DIR="$THEMES_DIR/$THEME"
for file in waybar-colors.css wofi-colors.css swaync-colors.css gtklock-colors.css gtk-colors.css kitty-theme.conf; do
    if [[ ! -s "$THEME_DIR/css/$file" ]]; then
        printf 'Error: theme %s is missing %s\n' "$THEME" "$file" >&2
        exit 1
    fi
done

# Theme palettes are trusted files from this repository.
# shellcheck source=/dev/null
source "$THEME_DIR/colors.conf"

mkdir -p "$CONFIG_DIR/waybar" "$CONFIG_DIR/wofi" "$CONFIG_DIR/swaync" \
    "$CONFIG_DIR/gtklock" "$CONFIG_DIR/swaylock" "$CONFIG_DIR/gtk-3.0" \
    "$CONFIG_DIR/kitty" "$CONFIG_DIR/dotfiles"
install -m 0644 "$THEME_DIR/css/waybar-colors.css" "$CONFIG_DIR/waybar/colors.css"
install -m 0644 "$THEME_DIR/css/wofi-colors.css" "$CONFIG_DIR/wofi/colors.css"
install -m 0644 "$THEME_DIR/css/swaync-colors.css" "$CONFIG_DIR/swaync/colors.css"
install -m 0644 "$THEME_DIR/css/gtklock-colors.css" "$CONFIG_DIR/gtklock/colors.css"
install -m 0644 "$THEME_DIR/css/gtk-colors.css" "$CONFIG_DIR/gtk-3.0/colors.css"
install -m 0644 "$THEME_DIR/css/kitty-theme.conf" "$CONFIG_DIR/kitty/theme.conf"

cat > "$CONFIG_DIR/swaylock/config" <<EOF
color=${COLOR_BG#\#}
show-failed-attempts
ignore-empty-password
ring-color=${COLOR_PRIMARY#\#}
inside-color=${COLOR_BG#\#}
line-color=${COLOR_BG#\#}
separator-color=${COLOR_BG#\#}
key-hl-color=${COLOR_ACCENT#\#}
bs-hl-color=${COLOR_ERROR#\#}
ring-ver-color=${COLOR_SECONDARY#\#}
inside-ver-color=${COLOR_BG#\#}
text-ver-color=${COLOR_FG#\#}
ring-wrong-color=${COLOR_ERROR#\#}
inside-wrong-color=${COLOR_BG#\#}
text-wrong-color=${COLOR_ERROR#\#}
text-color=${COLOR_FG#\#}
layout-text-color=${COLOR_FG#\#}
EOF

if [[ "$SEED_ONLY" != "--seed-only" ]]; then
    if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        if command -v timeout >/dev/null 2>&1; then
            timeout 3s hyprctl eval "hl.config({ general = { col = { active_border = $HYPR_BORDER_ACTIVE_LUA } } })" >/dev/null 2>&1 || true
            timeout 3s hyprctl eval "hl.config({ general = { col = { inactive_border = '$HYPR_BORDER_INACTIVE' } } })" >/dev/null 2>&1 || true
            timeout 3s hyprctl eval "hl.config({ ['decoration.shadow.color'] = '$HYPR_SHADOW' })" >/dev/null 2>&1 || true
        fi
    fi

    pkill -SIGUSR2 waybar 2>/dev/null || true
    if command -v swaync-client >/dev/null 2>&1 && command -v timeout >/dev/null 2>&1; then
        timeout 3s swaync-client --reload-css >/dev/null 2>&1 || true
    fi
    if command -v kitty >/dev/null 2>&1 && command -v timeout >/dev/null 2>&1; then
        kitty_target="${KITTY_LISTEN_ON:-unix:/tmp/kitty}"
        timeout 3s kitty @ --to "$kitty_target" set-colors --all "$CONFIG_DIR/kitty/theme.conf" >/dev/null 2>&1 || true
    fi
fi

WALLPAPER="$REQUESTED_WALLPAPER"
if [[ -n "$WALLPAPER" ]]; then
    WALLPAPER="${WALLPAPER/#\~/$HOME}"
    [[ "$WALLPAPER" = /* ]] || WALLPAPER="$(pwd)/$WALLPAPER"
elif [[ -s "$CONFIG_DIR/dotfiles/current_wallpaper" ]]; then
    IFS= read -r WALLPAPER < "$CONFIG_DIR/dotfiles/current_wallpaper" || true
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    WALLPAPER=""
    if [[ -n "${THEME_WALLPAPER_DEFAULT:-}" && -f "$THEME_DIR/wallpapers/$THEME_WALLPAPER_DEFAULT" ]]; then
        WALLPAPER="$THEME_DIR/wallpapers/$THEME_WALLPAPER_DEFAULT"
    elif [[ -d "$THEME_DIR/wallpapers" ]]; then
        WALLPAPER="$(find "$THEME_DIR/wallpapers" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print 2>/dev/null | sort | head -n 1)"
    fi
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    FALLBACK="$THEMES_DIR/tokyo-night/wallpapers/blue.png"
    [[ -f "$FALLBACK" ]] && WALLPAPER="$FALLBACK"
fi

printf '%s\n' "$THEME" > "$CONFIG_DIR/dotfiles/current_theme"
if [[ -n "$WALLPAPER" && -x "$CONFIG_DIR/scripts/wallpaper-set.sh" ]]; then
    if [[ "$SEED_ONLY" == "--seed-only" ]]; then
        printf '%s\n' "$WALLPAPER" > "$CONFIG_DIR/dotfiles/current_wallpaper"
        if [[ -x "$CONFIG_DIR/scripts/prepare-lock-wallpaper.sh" ]]; then
            "$CONFIG_DIR/scripts/prepare-lock-wallpaper.sh" "$WALLPAPER" >/dev/null 2>&1 || true
        fi
    else
        "$CONFIG_DIR/scripts/wallpaper-set.sh" "$WALLPAPER"
    fi
fi

if [[ "$QUIET" != "--quiet" ]] && command -v notify-send >/dev/null 2>&1; then
    notify-send -a dotFiles "Theme applied" "Active theme: $THEME" 2>/dev/null || true
fi
printf "Theme '%s' applied.\n" "$THEME"
