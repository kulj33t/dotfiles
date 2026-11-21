#!/usr/bin/env bash
# Resolve paths, detect the target system, and validate supported platforms.

normalize_absolute_path() {
    local input_path="$1"
    local normalized=/ remaining component candidate physical=/
    local -a components=()

    IFS=/ read -r -a components <<< "$input_path"
    for component in "${components[@]}"; do
        case "$component" in
            ''|.) ;;
            ..)
                normalized="${normalized%/*}"
                [[ -n "$normalized" ]] || normalized=/
                ;;
            *) normalized="${normalized%/}/$component" ;;
        esac
    done

    remaining="${normalized#/}"
    while [[ -n "$remaining" ]]; do
        component="${remaining%%/*}"
        if [[ "$remaining" == */* ]]; then
            remaining="${remaining#*/}"
        else
            remaining=
        fi
        candidate="${physical%/}/$component"
        if [[ -d "$candidate" ]]; then
            physical="$(cd "$candidate" && pwd -P)" || return 1
        elif [[ -e "$candidate" || -L "$candidate" ]]; then
            if [[ -n "$remaining" ]]; then
                printf 'Path component is not a directory: %s\n' "$candidate" >&2
                return 1
            fi
            physical="$candidate"
        else
            physical="$candidate"
            if [[ -n "$remaining" ]]; then
                physical="${physical%/}/$remaining"
            fi
            break
        fi
    done
    printf '%s\n' "$physical"
}

installer_context_init() {
    local repo_dir="$1"
    local required_path required_file required_command home_real

    if [[ -n "${XDG_CONFIG_HOME:-}" && "$XDG_CONFIG_HOME" != /* ]]; then
        printf 'XDG_CONFIG_HOME must be an absolute path: %s\n' "$XDG_CONFIG_HOME" >&2
        return 1
    fi
    CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    CONFIG_HOME="$(normalize_absolute_path "$CONFIG_HOME")" || return 1
    home_real="$(normalize_absolute_path "$HOME")" || return 1

    if [[ "$CONFIG_HOME" == / || "$CONFIG_HOME" == "$home_real" || \
          "$CONFIG_HOME" == "$repo_dir" || "$CONFIG_HOME" == "$repo_dir/"* || \
          "$repo_dir" == "$CONFIG_HOME/"* ]]; then
        printf 'XDG_CONFIG_HOME must be separate from the home root and dotfiles checkout: %s\n' "$CONFIG_HOME" >&2
        return 1
    fi
    if [[ -e "$CONFIG_HOME" && ! -d "$CONFIG_HOME" ]]; then
        printf 'XDG_CONFIG_HOME must be a directory: %s\n' "$CONFIG_HOME" >&2
        return 1
    fi
    export XDG_CONFIG_HOME="$CONFIG_HOME"

    for required_path in config scripts themes home installer; do
        if [[ ! -d "$repo_dir/$required_path" ]]; then
            printf 'Installer source directory is missing: %s\n' "$repo_dir/$required_path" >&2
            return 1
        fi
    done
    if (( EUID == 0 )); then
        echo 'Run this installer as your regular user, not root.' >&2
        return 1
    fi
    for required_command in bash sudo; do
        if ! command -v "$required_command" >/dev/null 2>&1; then
            printf 'Required command is missing: %s\n' "$required_command" >&2
            return 1
        fi
    done

    # shellcheck source=/dev/null
    source "$repo_dir/installer/lib/detect-distro.sh"
    DISTRO="$(detect_distro)"
    if [[ "$DISTRO" == fedora ]]; then
        # detect_distro runs in command substitution; reload release values here.
        # shellcheck source=/dev/null
        source /etc/os-release
        FEDORA_VERSION="${VERSION_ID:-}"
        FEDORA_VERSION="${FEDORA_VERSION%%.*}"
    fi

    case "$DISTRO" in
        arch|fedora|opensuse|debian) ;;
        debian-unsupported)
            echo 'Supported Debian release: Debian 13 (Trixie), with official Trixie backports.' >&2
            return 1
            ;;
        fedora-unsupported)
            echo 'Supported Fedora targets: package-managed Fedora 43–45 on x86_64 or aarch64. Fedora Atomic editions need a different deployment flow.' >&2
            return 1
            ;;
        opensuse-unsupported)
            echo 'This installer supports package-managed openSUSE Tumbleweed. MicroOS, Aeon, and Kalpa require a different deployment flow.' >&2
            return 1
            ;;
        *)
            printf 'Unsupported distribution: %s\n' "$DISTRO" >&2
            echo 'Targets: x86_64 Arch Linux, Fedora 43–45 (x86_64 or aarch64), openSUSE Tumbleweed, Debian 13 Trixie.' >&2
            return 1
            ;;
    esac

    for required_file in \
        "$repo_dir/installer/lib/detect-distro.sh" \
        "$repo_dir/installer/lib/packages/common.sh" \
        "$repo_dir/installer/lib/packages/$DISTRO.sh" \
        "$repo_dir/installer/lib/backup.sh" \
        "$repo_dir/installer/lib/deploy.sh" \
        "$repo_dir/installer/lib/detect-hardware.sh" \
        "$repo_dir/installer/lib/fonts.sh" \
        "$repo_dir/scripts/start-polkit-agent.sh"; do
        if [[ ! -r "$required_file" ]]; then
            printf 'Installer module is missing or unreadable: %s\n' "$required_file" >&2
            return 1
        fi
    done

    ARCH="$(uname -m)"
    case "$DISTRO" in
        arch) PACKAGE_MANAGER=pacman ;;
        fedora) PACKAGE_MANAGER=dnf ;;
        opensuse) PACKAGE_MANAGER=zypper ;;
        debian) PACKAGE_MANAGER=apt-get ;;
    esac
    if ! command -v "$PACKAGE_MANAGER" >/dev/null 2>&1; then
        printf 'Required package manager is missing for %s: %s\n' "$DISTRO" "$PACKAGE_MANAGER" >&2
        return 1
    fi
    if [[ "$DISTRO" == arch && "$ARCH" != x86_64 ]]; then
        printf 'The official Arch package map targets x86_64; detected %s.\n' "$ARCH" >&2
        return 1
    fi

    printf 'Detected target: %s (%s)\n' "$DISTRO" "$ARCH"
    case "$DISTRO:$ARCH" in
        fedora:aarch64)
            if [[ "$FEDORA_VERSION" == 45 ]]; then
                echo 'Fedora 45 aarch64 uses the hermitfeather/hyprland COPR for Hyprland.'
            else
                echo 'Fedora 43–44 aarch64 uses the nett00n/hyprland COPR for Hyprland.'
            fi
            ;;
        fedora:x86_64)
            echo 'Fedora x86_64 uses the ashbuk/Hyprland-Fedora COPR for Hyprland.'
            ;;
        debian:*)
            echo 'Debian installs Hyprland from official Trixie backports.'
            ;;
    esac
}
