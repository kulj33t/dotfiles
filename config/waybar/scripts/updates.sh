#!/usr/bin/env bash
# Read cached counts in the bar. Update checks run in the background with a timeout.

set -u
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
CACHE_FILE="$CACHE_DIR/updates.json"
mkdir -p "$CACHE_DIR"

update_count() {
    local output=''
    if command -v timeout >/dev/null 2>&1; then
        if command -v pacman >/dev/null 2>&1; then
            if command -v checkupdates >/dev/null 2>&1; then
                output=$(timeout 12 checkupdates 2>/dev/null || true)
            else
                output=$(timeout 12 pacman -Qu 2>/dev/null || true)
            fi
        elif command -v dnf >/dev/null 2>&1; then
            output=$(timeout 12 dnf check-update --quiet 2>/dev/null || true)
        elif command -v zypper >/dev/null 2>&1; then
            output=$(timeout 12 zypper --non-interactive --quiet list-updates 2>/dev/null || true)
        elif command -v apt-get >/dev/null 2>&1; then
            output=$(timeout 12 apt-get -s upgrade 2>/dev/null || true)
        fi
    fi

    case "$(command -v pacman >/dev/null && echo arch || command -v dnf >/dev/null && echo fedora || command -v zypper >/dev/null && echo opensuse || command -v apt-get >/dev/null && echo debian || echo unknown)" in
        arch) printf '%s\n' "$output" | awk 'NF {n++} END {print n+0}' ;;
        fedora) printf '%s\n' "$output" | awk 'NF >= 3 && $1 !~ /^(Last|Obsoleting|Security)/ {n++} END {print n+0}' ;;
        opensuse) printf '%s\n' "$output" | awk -F'|' 'NR > 2 && $1 ~ /v/ {n++} END {print n+0}' ;;
        debian) printf '%s\n' "$output" | awk '/^Inst / {n++} END {print n+0}' ;;
        *) printf '0\n' ;;
    esac
}

if [[ "${1:-}" == check ]]; then
    printf '{"text":"…","tooltip":"Checking for package updates","class":"pending"}\n' > "$CACHE_FILE"
    pkill -SIGRTMIN+8 waybar 2>/dev/null || true
    (
        count=$(update_count)
        if [[ "$count" =~ ^[0-9]+$ ]] && (( count > 0 )); then
            printf '{"text":"%s","tooltip":"%s updates available","class":"pending"}\n' "$count" "$count" > "$CACHE_FILE.tmp"
        else
            printf '{"text":"0","tooltip":"No updates reported","class":"updated"}\n' > "$CACHE_FILE.tmp"
        fi
        mv "$CACHE_FILE.tmp" "$CACHE_FILE"
        pkill -SIGRTMIN+8 waybar 2>/dev/null || true
    ) >/dev/null 2>&1 &
    exit 0
fi

if [[ -s "$CACHE_FILE" ]]; then
    cat "$CACHE_FILE"
else
    printf '{"text":"0","tooltip":"Click to check for package updates","class":"updated"}\n'
fi
