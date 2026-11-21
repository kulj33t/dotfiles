#!/usr/bin/env bash
# Build the GTKLock v4 user and power modules into the user's config tree.

install_gtklock_modules() {
    local config_home="$1"
    local gtklock_version major minor work_dir module_dir tool
    local userinfo_build powerbar_build userinfo_so powerbar_so

    if ! command -v gtklock >/dev/null 2>&1; then
        echo 'GTKLock is not installed; skipping its optional UI modules.'
        return 0
    fi

    gtklock_version="$(gtklock --version 2>/dev/null || true)"
    if [[ ! "$gtklock_version" =~ v?([0-9]+)\.([0-9]+)\. ]]; then
        echo 'Could not read the GTKLock version; skipping optional UI modules.' >&2
        return 1
    fi
    major="${BASH_REMATCH[1]}"
    minor="${BASH_REMATCH[2]}"
    if [[ "$major.$minor" != 4.0 ]]; then
        printf 'GTKLock %s is not compatible with the pinned v4.0 modules; skipping them.\n' \
            "$gtklock_version" >&2
        return 1
    fi

    module_dir="$config_home/gtklock/modules/v4.0"
    if [[ -s "$module_dir/userinfo-module.so" && -s "$module_dir/powerbar-module.so" ]]; then
        echo 'GTKLock v4 user and power modules are already installed.'
        return 0
    fi

    for tool in git meson ninja pkg-config cc; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            printf 'Missing build tool %s; skipping GTKLock UI modules.\n' "$tool" >&2
            return 1
        fi
    done
    if ! pkg-config --exists gtk+-3.0 gmodule-export-2.0 accountsservice; then
        echo 'GTKLock module development libraries are missing; skipping UI modules.' >&2
        return 1
    fi

    work_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-gtklock-modules.XXXXXX")" || return 1
    userinfo_build="$work_dir/userinfo-build"
    powerbar_build="$work_dir/powerbar-build"

    if ! git clone --quiet --depth 1 --branch v4.0.0 \
        https://github.com/jovanlanik/gtklock-userinfo-module.git "$work_dir/userinfo" || \
        ! git clone --quiet --depth 1 --branch v4.0.0 \
        https://github.com/jovanlanik/gtklock-powerbar-module.git "$work_dir/powerbar"; then
        rm -rf -- "$work_dir"
        echo 'Could not download the pinned GTKLock v4 modules; using the basic lock layout.' >&2
        return 1
    fi

    if ! meson setup "$userinfo_build" "$work_dir/userinfo" >/dev/null || \
        ! meson compile -C "$userinfo_build" >/dev/null || \
        ! meson setup "$powerbar_build" "$work_dir/powerbar" >/dev/null || \
        ! meson compile -C "$powerbar_build" >/dev/null; then
        rm -rf -- "$work_dir"
        echo 'Could not build GTKLock UI modules; using the basic lock layout.' >&2
        return 1
    fi

    userinfo_so="$(find "$userinfo_build" -maxdepth 2 -type f -name userinfo-module.so -print -quit)"
    powerbar_so="$(find "$powerbar_build" -maxdepth 2 -type f -name powerbar-module.so -print -quit)"
    if [[ -z "$userinfo_so" || -z "$powerbar_so" ]]; then
        rm -rf -- "$work_dir"
        echo 'The GTKLock module builds did not produce both modules; using the basic lock layout.' >&2
        return 1
    fi

    if ! mkdir -p "$work_dir/staged" || \
        ! install -m 0755 "$userinfo_so" "$work_dir/staged/userinfo-module.so" || \
        ! install -m 0755 "$powerbar_so" "$work_dir/staged/powerbar-module.so" || \
        ! install -d -m 0755 "$module_dir" || \
        ! install -m 0755 "$work_dir/staged/userinfo-module.so" "$module_dir/userinfo-module.so" || \
        ! install -m 0755 "$work_dir/staged/powerbar-module.so" "$module_dir/powerbar-module.so"; then
        rm -rf -- "$work_dir"
        echo 'Could not install GTKLock UI modules; using the basic lock layout.' >&2
        return 1
    fi

    rm -rf -- "$work_dir"
    echo "Installed GTKLock v4 user and power modules to $module_dir."
}
