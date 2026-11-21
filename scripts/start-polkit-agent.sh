#!/usr/bin/env bash
# Ensure a graphical Polkit agent is available for actions such as reboot.

set -u

user_id="${UID:-$(id -u)}"
agent_pattern='polkit-(mate|gnome)-authentication-agent-1|xfce-polkit|lxpolkit|lxqt-policykit-agent'

agent_is_running() {
    if command -v pgrep >/dev/null 2>&1; then
        pgrep -u "$user_id" -f "$agent_pattern" >/dev/null 2>&1
    else
        ps -u "$user_id" -o args= 2>/dev/null | grep -E "$agent_pattern" >/dev/null
    fi
}

if agent_is_running; then
    exit 0
fi

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd \
        WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE >/dev/null 2>&1 || true
fi

for agent in \
    /usr/libexec/polkit-mate-authentication-agent-1 \
    /usr/lib/mate-polkit/polkit-mate-authentication-agent-1 \
    polkit-mate-authentication-agent-1 \
    /usr/libexec/polkit-gnome-authentication-agent-1 \
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 \
    polkit-gnome-authentication-agent-1 \
    xfce-polkit \
    lxqt-policykit-agent \
    lxpolkit; do
    if [[ "$agent" == */* ]]; then
        [[ -x "$agent" ]] || continue
        agent_path="$agent"
    else
        agent_path="$(command -v "$agent" 2>/dev/null || true)"
        [[ -n "$agent_path" ]] || continue
    fi

    "$agent_path" >/dev/null 2>&1 &
    agent_pid=$!
    for _ in {1..20}; do
        if agent_is_running; then
            exit 0
        fi
        if ! kill -0 "$agent_pid" 2>/dev/null; then
            break
        fi
        sleep 0.1
    done

    if kill -0 "$agent_pid" 2>/dev/null; then
        exit 0
    fi
done

printf 'No graphical Polkit authentication agent could be started.\n' >&2
exit 1
