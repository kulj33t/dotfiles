#!/usr/bin/env bash

os_update_system() {
    echo 'Refreshing Debian repositories and upgrading installed packages...'
    if ! sudo apt-get update; then
        echo 'Debian repository refresh failed; no dotfiles were deployed.' >&2
        return 1
    fi
    if ! sudo env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y; then
        echo 'Debian package upgrade failed; no dotfiles were deployed.' >&2
        return 1
    fi
}

_install_required_debian() {
    sudo apt-get install -y "$@"
}

_install_optional_debian() {
    sudo apt-get install -y "$1"
}

os_install_packages() {
    # The supported Debian baseline is 13 (Trixie). Hyprland is in official backports.
    # shellcheck source=/dev/null
    source /etc/os-release
    if [[ "${VERSION_CODENAME:-${DEBIAN_CODENAME:-}}" != trixie ]]; then
        echo 'This installer supports Debian 13 Trixie. Other Debian releases are outside the package baseline.' >&2
        return 1
    fi

    local backports_file=/etc/apt/sources.list.d/dotfiles-trixie-backports.sources
    local source_file
    local has_backports_source=false

    for source_file in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
        [[ -f "$source_file" ]] || continue
        if grep -Eq '^[[:space:]]*deb(-src)?[[:space:]].*[[:space:]]trixie-backports([[:space:]]|$)' "$source_file"; then
            has_backports_source=true
            break
        fi
    done

    if [[ "$has_backports_source" == false ]]; then
        for source_file in /etc/apt/sources.list.d/*.sources; do
            [[ -f "$source_file" ]] || continue
            if awk '
                BEGIN { RS = ""; FS = "\n" }
                {
                    enabled = 1
                    suites_match = 0
                    in_suites = 0
                    for (i = 1; i <= NF; i++) {
                        line = $i
                        if (line ~ /^[[:space:]]*#/ || line ~ /^[[:space:]]*$/) continue
                        if (line ~ /^[[:space:]]*[[:alnum:]-]+:/) {
                            in_suites = (line ~ /^[[:space:]]*Suites:/)
                            if (tolower(line) ~ /^[[:space:]]*enabled:[[:space:]]*no([[:space:]]|$)/) enabled = 0
                            if (in_suites) {
                                sub(/^[[:space:]]*Suites:[[:space:]]*/, "", line)
                                if (line ~ /(^|[[:space:]])trixie-backports([[:space:]]|$)/) suites_match = 1
                            }
                        } else if (in_suites && line ~ /(^|[[:space:]])trixie-backports([[:space:]]|$)/) {
                            suites_match = 1
                        }
                    }
                    if (enabled && suites_match) found = 1
                }
                END { exit !found }
            ' "$source_file"; then
                has_backports_source=true
                break
            fi
        done
    fi

    if [[ "$has_backports_source" == false ]]; then
        echo 'Adding the official Debian Trixie backports source for Hyprland 0.55+.'
        if ! sudo tee "$backports_file" >/dev/null <<'EOF'
Types: deb
URIs: https://deb.debian.org/debian
Suites: trixie-backports
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
        then
            echo 'Could not add the Debian Trixie backports source.' >&2
            return 1
        fi
    fi

    if ! sudo apt-get update; then
        echo 'Could not refresh Debian package indexes after checking backports.' >&2
        return 1
    fi
    if ! LC_ALL=C apt-cache policy hyprland 2>/dev/null | grep 'trixie-backports' >/dev/null; then
        echo 'Hyprland is not visible from an active Trixie backports source after apt update.' >&2
        echo 'Check the source configuration and network, then rerun the installer.' >&2
        return 1
    fi

    install_required_packages 'Debian Hyprland' _install_required_debian hyprland/trixie-backports || return 1

    local required=(
        waybar wofi kitty sway-notification-center swayidle swaylock swaybg
        xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xwayland
    )
    local optional=(
        cliphist wl-clipboard brightnessctl playerctl grim slurp jq
        zsh fastfetch htop thunar xdg-utils libnotify-bin fontconfig adwaita-icon-theme
        pavucontrol blueman wireplumber pipewire-pulse curl tar xz-utils procps
        gtklock swappy awww network-manager network-manager-gnome policykit-1-gnome
    )

    install_required_packages 'Debian' _install_required_debian "${required[@]}" || return 1
    install_optional_packages _install_optional_debian "${optional[@]}"
}
