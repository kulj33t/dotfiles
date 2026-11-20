#!/usr/bin/env bash
# Orchestrate platform checks, system updates, package installation, and deployment.

set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

source "$REPO_DIR/installer/lib/context.sh"
installer_context_init "$REPO_DIR"

source "$REPO_DIR/installer/lib/packages/common.sh"
source "$REPO_DIR/installer/lib/packages/$DISTRO.sh"
source "$REPO_DIR/installer/lib/backup.sh"
source "$REPO_DIR/installer/lib/deploy.sh"
source "$REPO_DIR/installer/lib/detect-hardware.sh"
source "$REPO_DIR/installer/lib/fonts.sh"

read -r -p 'Update system packages, install the desktop packages, and deploy these configs? [y/N]: ' confirm
[[ "$confirm" =~ ^[yY]$ ]] || { echo 'Cancelled.'; exit 0; }
if ! sudo -v; then
    echo 'Could not authenticate with sudo; no system changes were made.' >&2
    exit 1
fi

os_update_system
os_install_packages

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

# Generate theme files/state without contacting a running compositor or app IPC socket.
bash "$CONFIG_HOME/scripts/theme-switch.sh" tokyo-night "" --quiet --seed-only

cat <<EOF

Configuration deployed to: $CONFIG_HOME
Hyprland: Lua config for version 0.55 and newer
Lock screen: GTKLock when available; swaylock fallback
Wallpaper: swaybg baseline; awww transitions when its package is available

Hyprland auto-starts for Bash logins on TTY1; display-manager setup is unchanged.
The installer updated the system packages and did not change GPU or boot settings.
EOF

if (( OPTIONAL_PACKAGE_SKIPPED > 0 )); then
    printf '%s optional packages were skipped. Details: %s\n' \
        "$OPTIONAL_PACKAGE_SKIPPED" "$OPTIONAL_PACKAGE_LOG"
fi
