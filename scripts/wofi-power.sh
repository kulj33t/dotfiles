#!/usr/bin/env bash
set -u

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
OPT_LOCK="Lock Session"
OPT_SUSPEND="Suspend System"
OPT_REBOOT="Restart"
OPT_SHUTDOWN="Power Off"
OPT_LOGOUT="Exit Hyprland"

notify_failure() {
    local action="$1" detail="${2:-}"
    if command -v notify-send >/dev/null 2>&1; then
        detail="${detail//$'\n'/ }"
        [[ -n "$detail" ]] || detail='The action was denied or logind returned an error.'
        notify-send -a dotFiles --urgency=critical \
            "Power action failed" "$action: $detail" 2>/dev/null || true
    fi
}

run_logind_action() {
    local action="$1"
    if ! command -v loginctl >/dev/null 2>&1; then
        notify_failure "$action"
        printf 'loginctl is unavailable; cannot run %s.\n' "$action" >&2
        return 1
    fi

    if [[ -x "$CONFIG_DIR/scripts/start-polkit-agent.sh" ]] && \
        ! bash "$CONFIG_DIR/scripts/start-polkit-agent.sh"; then
        notify_failure "$action" 'No graphical Polkit authentication agent is available.'
        return 1
    fi

    local action_output
    if ! action_output="$(loginctl "$action" 2>&1)"; then
        notify_failure "$action" "$action_output"
        [[ -n "$action_output" ]] && printf '%s\n' "$action_output" >&2
        return 1
    fi
    return 0
}

if ! command -v wofi >/dev/null 2>&1; then
    notify_failure 'Power menu'
    printf 'wofi is unavailable; cannot display the power menu.\n' >&2
    exit 1
fi

CHOICE=$(printf '%s\n' "$OPT_LOCK" "$OPT_SUSPEND" "$OPT_REBOOT" "$OPT_SHUTDOWN" "$OPT_LOGOUT" | \
    wofi --show dmenu --prompt "Power Menu" --location 0 --cache-file /dev/null)

case "$CHOICE" in
    "$OPT_LOCK") bash "$CONFIG_DIR/scripts/lock.sh" ;;
    "$OPT_SUSPEND") run_logind_action suspend ;;
    "$OPT_REBOOT") run_logind_action reboot ;;
    "$OPT_SHUTDOWN") run_logind_action poweroff ;;
    "$OPT_LOGOUT")
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl dispatch 'hl.dsp.exit()' || notify_failure "Exit Hyprland"
        else
            notify_failure "Exit Hyprland"
            printf 'hyprctl is unavailable; cannot exit Hyprland.\n' >&2
            exit 1
        fi
        ;;
esac
