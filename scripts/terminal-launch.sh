#!/usr/bin/env bash
set -u

# Prefer Kitty when installed. Its remote-control socket lets repeated Super+T
# presses create separate OS windows in the same Kitty instance.
if command -v kitty >/dev/null 2>&1; then
    kitty_target="${KITTY_LISTEN_ON:-unix:/tmp/kitty}"
    if (( $# == 0 )); then
        if kitty @ --to "$kitty_target" launch --type=os-window >/dev/null 2>&1; then
            exit 0
        fi
    else
        if kitty @ --to "$kitty_target" launch --type=os-window "$@" >/dev/null 2>&1; then
            exit 0
        fi
    fi

    if (( $# == 0 )); then
        exec kitty
    fi
    exec kitty -e "$@"
fi

if command -v xdg-terminal-exec >/dev/null 2>&1; then
    if xdg-terminal-exec "$@"; then
        exit 0
    fi
fi

for terminal in ptyxis kgx gnome-terminal konsole foot alacritty xterm; do
    command -v "$terminal" >/dev/null 2>&1 || continue

    if (( $# == 0 )); then
        exec "$terminal"
    fi

    case "$terminal" in
        ptyxis)
            command_line=$(printf '%q ' "$@")
            exec ptyxis --execute "$command_line"
            ;;
        kgx)
            exec kgx --command "$@"
            ;;
        gnome-terminal)
            exec gnome-terminal -- "$@"
            ;;
        konsole)
            exec konsole -e "$@"
            ;;
        foot)
            exec foot "$@"
            ;;
        alacritty)
            exec "$terminal" -e "$@"
            ;;
        xterm)
            exec xterm -e "$@"
            ;;
    esac
done

if command -v notify-send >/dev/null 2>&1; then
    notify-send -a dotFiles 'Terminal unavailable' \
        'Install or select a terminal emulator, then try again.'
fi
printf 'No supported terminal command was found.\n' >&2
exit 1
