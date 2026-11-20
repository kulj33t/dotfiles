#!/usr/bin/env bash
# Shared package transaction handling for the per-distribution modules.

install_required_packages() {
    local distro_name="$1"
    local installer_function="$2"
    shift 2

    printf 'Installing %s core packages (%s packages)...\n' "$distro_name" "$#"
    if ! "$installer_function" "$@"; then
        printf 'The %s core package transaction failed; configuration deployment was stopped.\n' "$distro_name" >&2
        return 1
    fi
}

install_optional_packages() {
    local installer_function="$1"
    local package log_dir log_file
    shift
    OPTIONAL_PACKAGE_SKIPPED=0

    log_dir="$HOME/.local/state/dotfiles-installer"
    log_file="$log_dir/optional-packages.log"
    if mkdir -p "$log_dir" 2>/dev/null; then
        : > "$log_file"
    else
        log_file="${TMPDIR:-/tmp}/dotfiles-installer-optional-${UID:-user}.log"
        : > "$log_file" 2>/dev/null || log_file=/dev/null
    fi
    OPTIONAL_PACKAGE_LOG="$log_file"

    for package in "$@"; do
        printf 'Optional package %s: ' "$package"
        if "$installer_function" "$package" >> "$log_file" 2>&1; then
            printf 'installed.\n'
        else
            OPTIONAL_PACKAGE_SKIPPED=$((OPTIONAL_PACKAGE_SKIPPED + 1))
            printf 'skipped (unavailable or install failed).\n'
            if [[ "$log_file" != /dev/null ]]; then
                printf '  Package-manager details: %s\n' "$log_file"
            fi
        fi
    done
}
