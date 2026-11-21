#!/usr/bin/env bash
# GTKLock provides the custom UI; swaylock is the fast, secure fallback.

set -u
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCK_BACKGROUND=""

if pgrep -u "$UID" -x gtklock >/dev/null 2>&1 || pgrep -u "$UID" -x swaylock >/dev/null 2>&1; then
    exit 0
fi

if [[ -x "$CONFIG_DIR/scripts/prepare-lock-wallpaper.sh" ]]; then
    LOCK_BACKGROUND="$("$CONFIG_DIR/scripts/prepare-lock-wallpaper.sh" 2>/dev/null || true)"
    [[ -f "$LOCK_BACKGROUND" ]] || LOCK_BACKGROUND=""
fi

if command -v playerctl >/dev/null 2>&1; then
    playerctl pause >/dev/null 2>&1 || true
fi

if command -v gtklock >/dev/null 2>&1; then
    gtklock_args=(--daemonize --style "$CONFIG_DIR/gtklock/style.css")
    [[ -n "$LOCK_BACKGROUND" ]] && gtklock_args+=(--background "$LOCK_BACKGROUND")

    gtklock_version="$(gtklock --version 2>/dev/null || true)"
    module_dir="$CONFIG_DIR/gtklock/modules/v4.0"
    userinfo_loaded=0
    if [[ "$gtklock_version" =~ v?4\.0\. ]]; then
        if [[ -s "$module_dir/powerbar-module.so" ]]; then
            gtklock_args+=(--modules "$module_dir/powerbar-module.so")
        fi

        if [[ -s "$module_dir/userinfo-module.so" ]] && command -v busctl >/dev/null 2>&1; then
            busctl --system call org.freedesktop.DBus /org/freedesktop/DBus \
                org.freedesktop.DBus StartServiceByName su org.freedesktop.Accounts 0 \
                >/dev/null 2>&1 || true
            if busctl --system status org.freedesktop.Accounts >/dev/null 2>&1; then
                gtklock_args+=(--modules "$module_dir/userinfo-module.so")
                userinfo_loaded=1
            fi
        fi
    fi
    if (( userinfo_loaded )) && [[ -r "$CONFIG_DIR/gtklock/layout.ui" ]]; then
        gtklock_args+=(--layout "$CONFIG_DIR/gtklock/layout.ui")
    fi
    exec gtklock "${gtklock_args[@]}"
elif command -v swaylock >/dev/null 2>&1; then
    swaylock_args=(--config "$CONFIG_DIR/swaylock/config" --daemonize)
    [[ -n "$LOCK_BACKGROUND" ]] && swaylock_args+=(--image "$LOCK_BACKGROUND" --scaling fill)
    exec swaylock "${swaylock_args[@]}"
fi

command -v notify-send >/dev/null 2>&1 && notify-send -a dotFiles "No screen locker installed" "Install gtklock or swaylock." || true
exit 1
