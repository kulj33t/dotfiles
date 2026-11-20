#!/usr/bin/env bash
# Ordered session startup keeps generated theme files ready before UI daemons load.

set -u
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE 2>/dev/null || true
fi

bash "$CONFIG_DIR/scripts/theme-init.sh" || true

if ! pgrep -u "$UID" -x waybar >/dev/null 2>&1; then
    waybar >/dev/null 2>&1 &
fi
if ! pgrep -u "$UID" -x swaync >/dev/null 2>&1; then
    swaync >/dev/null 2>&1 &
fi

if ! pgrep -u "$UID" -f 'polkit-gnome-authentication-agent-1' >/dev/null 2>&1; then
    for agent in polkit-gnome-authentication-agent-1 \
        /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
        /usr/libexec/polkit-gnome-authentication-agent-1; do
        if command -v "$agent" >/dev/null 2>&1 || [[ -x "$agent" ]]; then
            "$agent" >/dev/null 2>&1 &
            break
        fi
    done
fi

if command -v cliphist >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; then
    wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
    wl-paste --type image --watch cliphist store >/dev/null 2>&1 &
fi

if command -v swayidle >/dev/null 2>&1 && ! pgrep -u "$UID" -x swayidle >/dev/null 2>&1; then
    swayidle -w \
        timeout 180 "$CONFIG_DIR/scripts/lock.sh" \
        timeout 300 "hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'" \
        resume "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'" \
        before-sleep "$CONFIG_DIR/scripts/lock.sh" >/dev/null 2>&1 &
fi
