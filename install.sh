#!/usr/bin/env bash
# Bootstrap the dotfiles on supported Linux distributions.

set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ -n "${XDG_CONFIG_HOME:-}" && "$XDG_CONFIG_HOME" != /* ]]; then
    printf 'XDG_CONFIG_HOME must be an absolute path: %s\n' "$XDG_CONFIG_HOME" >&2
    exit 1
fi
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

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

CONFIG_HOME="$(normalize_absolute_path "$CONFIG_HOME")" || exit 1
HOME_REAL="$(normalize_absolute_path "$HOME")" || exit 1
if [[ "$CONFIG_HOME" == / || "$CONFIG_HOME" == "$HOME_REAL" || \
      "$CONFIG_HOME" == "$REPO_DIR" || "$CONFIG_HOME" == "$REPO_DIR/"* || \
      "$REPO_DIR" == "$CONFIG_HOME/"* ]]; then
    printf 'XDG_CONFIG_HOME must be a separate directory outside the home root and dotfiles checkout: %s\n' "$CONFIG_HOME" >&2
    exit 1
fi
if [[ -e "$CONFIG_HOME" && ! -d "$CONFIG_HOME" ]]; then
    printf 'XDG_CONFIG_HOME must be a directory: %s\n' "$CONFIG_HOME" >&2
    exit 1
fi
export XDG_CONFIG_HOME="$CONFIG_HOME"

for required_path in config scripts themes home installer; do
    if [[ ! -d "$REPO_DIR/$required_path" ]]; then
        printf 'Installer source directory is missing: %s\n' "$REPO_DIR/$required_path" >&2
        exit 1
    fi
done

if (( EUID == 0 )); then
    echo 'Run this installer as your regular user, not root.' >&2
    exit 1
fi

for command_name in bash sudo; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Required command is missing: %s\n' "$command_name" >&2
        exit 1
    fi
done

source "$REPO_DIR/installer/lib/detect-distro.sh"
DISTRO=$(detect_distro)
case "$DISTRO" in
    arch|fedora|opensuse|debian) ;;
    debian-unsupported)
        echo 'Supported Debian release: Debian 13 (Trixie), with official Trixie backports.' >&2
        exit 1
        ;;
    fedora-unsupported)
        echo 'Supported Fedora targets: package-managed Fedora 43–45 on x86_64 or aarch64. Fedora Atomic editions need a different deployment flow.' >&2
        exit 1
        ;;
    opensuse-unsupported)
        echo 'This installer supports package-managed openSUSE Tumbleweed. MicroOS, Aeon, and Kalpa require a different deployment flow.' >&2
        exit 1
        ;;
    *)
        printf 'Unsupported distribution: %s\n' "$DISTRO" >&2
        echo 'Targets: x86_64 Arch Linux, Fedora 43–45 (x86_64 or aarch64), openSUSE Tumbleweed, Debian 13 Trixie.' >&2
        exit 1
        ;;
esac

case "$DISTRO" in
    arch) package_manager=pacman ;;
    fedora) package_manager=dnf ;;
    opensuse) package_manager=zypper ;;
    debian) package_manager=apt-get ;;
esac
if ! command -v "$package_manager" >/dev/null 2>&1; then
    printf 'Required package manager is missing for %s: %s\n' "$DISTRO" "$package_manager" >&2
    exit 1
fi

if [[ "$DISTRO" == arch && "$(uname -m)" != x86_64 ]]; then
    printf 'The Arch package map targets official x86_64 Arch Linux; detected %s.\n' "$(uname -m)" >&2
    exit 1
fi

printf 'Detected target: %s (%s)\n' "$DISTRO" "$(uname -m)"
if [[ "$DISTRO" == fedora ]]; then
    if [[ "$(uname -m)" == aarch64 ]]; then
        if [[ "${VERSION_ID%%.*}" == 45 ]]; then
            echo 'Fedora 45 aarch64 uses the hermitfeather/hyprland COPR for the Lua-compatible Hyprland build.'
        else
            echo 'Fedora 43–44 aarch64 uses the nett00n/hyprland COPR for the Lua-compatible Hyprland build.'
        fi
    else
        echo 'Fedora x86_64 uses the ashbuk/Hyprland-Fedora COPR for the Lua-compatible Hyprland build.'
    fi
elif [[ "$DISTRO" == debian ]]; then
    echo 'Debian installs Hyprland from the official Trixie backports repository.'
fi
read -r -p 'Install packages and deploy these dotfiles? [y/N]: ' confirm
[[ "$confirm" =~ ^[yY]$ ]] || { echo 'Cancelled.'; exit 0; }
sudo -v

source "$REPO_DIR/installer/lib/backup.sh"
source "$REPO_DIR/installer/lib/deploy.sh"
source "$REPO_DIR/installer/lib/detect-hardware.sh"
source "$REPO_DIR/installer/lib/fonts.sh"

case "$DISTRO" in
    arch) source "$REPO_DIR/installer/lib/packages/arch.sh"; install_packages_arch ;;
    fedora) source "$REPO_DIR/installer/lib/packages/fedora.sh"; install_packages_fedora ;;
    opensuse) source "$REPO_DIR/installer/lib/packages/opensuse.sh"; install_packages_opensuse ;;
    debian) source "$REPO_DIR/installer/lib/packages/debian.sh"; install_packages_debian ;;
esac

check_hyprland_version() {
    local version_line major minor
    if ! command -v Hyprland >/dev/null 2>&1; then
        echo 'Hyprland was not installed. Check the package output and repository setup.' >&2
        return 1
    fi
    version_line=$(Hyprland --version 2>&1 | head -n 1 || true)
    if [[ "$version_line" =~ ([0-9]+)\.([0-9]+) ]]; then
        major=${BASH_REMATCH[1]}
        minor=${BASH_REMATCH[2]}
        if (( major == 0 && minor < 55 )); then
            printf 'Hyprland %s is too old; this config requires 0.55 or newer.\n' "$version_line" >&2
            return 1
        fi
        printf 'Hyprland version accepted: %s\n' "$version_line"
    else
        printf 'Could not parse Hyprland version output: %s\n' "$version_line" >&2
        return 1
    fi
}
check_hyprland_version

backup_existing_configs "$REPO_DIR"
deploy_configs "$REPO_DIR"
install_fonts
configure_hardware "$CONFIG_HOME"

# Seed runtime palette files before the first Hyprland session starts.
bash "$CONFIG_HOME/scripts/theme-switch.sh" tokyo-night "" --quiet

cat <<EOF

Configuration deployed to: $CONFIG_HOME
Hyprland: Lua config for version 0.55 and newer
Lock screen: GTKLock when available; swaylock fallback
Wallpaper: swaybg baseline; awww transitions when its package is available

Start Hyprland from your display manager or a local TTY login. The installer does not
change your login manager or system-wide GPU/boot settings.
EOF
