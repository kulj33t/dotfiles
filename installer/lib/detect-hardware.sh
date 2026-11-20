#!/usr/bin/env bash
# Report hardware without forcing driver or renderer overrides.

configure_hardware() {
    local vendor_file vendor nvidia_count=0 gpu_count=0 has_battery=false
    for vendor_file in /sys/class/drm/card[0-9]*/device/vendor; do
        [[ -r "$vendor_file" ]] || continue
        read -r vendor < "$vendor_file" || continue
        gpu_count=$((gpu_count + 1))
        [[ "${vendor,,}" == 0x10de ]] && nvidia_count=$((nvidia_count + 1))
    done

    if (( nvidia_count > 0 )); then
        echo ' -> NVIDIA GPU detected; keeping the compositor and driver defaults unchanged.'
    elif [[ -r /proc/device-tree/compatible ]] && tr -d '\000' </proc/device-tree/compatible | grep -qiE 'apple|asahi'; then
        echo ' -> Apple Silicon/Asahi detected; keeping the standard Mesa defaults.'
    else
        echo ' -> No NVIDIA override needed; keeping standard GPU defaults.'
    fi

    if find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -print -quit 2>/dev/null | grep -q .; then
        has_battery=true
    fi
    if [[ "$has_battery" == true ]]; then
        echo ' -> Battery found; Waybar battery module remains enabled.'
    else
        echo ' -> No battery found; Waybar will hide unavailable power modules.'
    fi
    printf ' -> Architecture: %s\n' "$(uname -m)"
}
