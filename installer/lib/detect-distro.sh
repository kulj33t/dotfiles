#!/usr/bin/env bash
# Supported installer targets: Arch, Fedora, openSUSE Tumbleweed, Debian 13.

detect_distro() {
    [[ -r /etc/os-release ]] || { echo unknown; return; }
    # shellcheck source=/dev/null
    source /etc/os-release

    case "${ID:-}" in
        arch) echo arch ;;
        fedora)
            local fedora_version="${VERSION_ID:-}"
            fedora_version="${fedora_version%%.*}"
            local variant_id
            variant_id="$(printf '%s' "${VARIANT_ID:-}" | tr '[:upper:]' '[:lower:]')"
            if [[ ! "$fedora_version" =~ ^(43|44|45)$ || ! "$(uname -m)" =~ ^(x86_64|aarch64)$ ]]; then
                echo fedora-unsupported
                return
            fi
            case "$variant_id" in
                *atomic*|silverblue|kinoite|sericea|coreos|iot|cloud)
                    echo fedora-unsupported
                    ;;
                *) echo fedora ;;
            esac
            ;;
        opensuse-tumbleweed)
            local variant_id
            variant_id="$(printf '%s' "${VARIANT_ID:-}" | tr '[:upper:]' '[:lower:]')"
            case "$variant_id" in
                *microos*|aeon|kalpa|*immutable*)
                    echo opensuse-unsupported
                    ;;
                *) echo opensuse ;;
            esac
            ;;
        opensuse|opensuse-leap) echo opensuse-unsupported ;;
        debian)
            if [[ "${VERSION_CODENAME:-}" == trixie || "${DEBIAN_CODENAME:-}" == trixie ]]; then
                echo debian
            else
                echo debian-unsupported
            fi
            ;;
        *) echo unknown ;;
    esac
}
