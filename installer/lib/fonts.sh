#!/usr/bin/env bash
# JetBrainsMono Nerd Font TTFs are architecture-independent; install them per user.

install_fonts() {
    local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
    local archive

    if command -v fc-list >/dev/null 2>&1 && fc-list : family 2>/dev/null | grep -i 'JetBrainsMono Nerd Font' >/dev/null; then
        echo ' -> JetBrainsMono Nerd Font is already available.'
        return 0
    fi
    if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
        echo ' -> Font download skipped; install curl and tar, then rerun the installer.' >&2
        return 0
    fi

    mkdir -p "$font_dir"
    archive=$(mktemp "${TMPDIR:-/tmp}/jetbrains-nerd-font.XXXXXX.tar.xz") || return 0
    if ! curl -fL --retry 2 --connect-timeout 15 --max-time 120 \
        'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz' \
        -o "$archive"; then
        rm -f "$archive"
        echo ' -> Font download failed; install JetBrainsMono Nerd Font manually.' >&2
        return 0
    fi
    if ! tar -tf "$archive" | grep -E '\.ttf$' >/dev/null; then
        rm -f "$archive"
        echo ' -> Download did not contain TTF font files; leaving fonts unchanged.' >&2
        return 0
    fi
    if ! tar -xf "$archive" -C "$font_dir"; then
        rm -f "$archive"
        echo ' -> Font archive could not be extracted.' >&2
        return 0
    fi
    rm -f "$archive"
    command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$font_dir" >/dev/null 2>&1 || true
    echo " -> Installed JetBrainsMono Nerd Font to $font_dir"
}
