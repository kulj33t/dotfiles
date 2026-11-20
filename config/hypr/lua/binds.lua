local function command(keys, cmd, flags)
    hl.bind(keys, hl.dsp.exec_cmd(cmd), flags or {})
end

local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local scripts = config_home .. "/scripts/"

command("SUPER + T", "kitty")
command("SUPER + Q", "hyprctl dispatch killactive")
command("SUPER + SHIFT + M", "hyprctl dispatch exit")
command("SUPER + E", "thunar")
command("SUPER + SPACE", "wofi --show drun")
command("SUPER + B", "xdg-open https://")
command("SUPER + A", "pavucontrol")
command("SUPER + L", scripts .. "lock.sh")
command("SUPER + N", "swaync-client -t -s")
command("SUPER + F", "hyprctl dispatch togglefloating; hyprctl dispatch centerwindow")
command("SUPER + J", "hyprctl dispatch layoutmsg togglesplit")

command("SUPER + SHIFT + L", scripts .. "wofi-power.sh")
command("SUPER + SHIFT + S", scripts .. "wofi-screenshot.sh")
command("SUPER + SHIFT + T", scripts .. "wofi-theme.sh")
command("SUPER + V", scripts .. "wofi-clipboard.sh")
command("SUPER + SHIFT + W", scripts .. "wofi-wallpaper.sh")

for key, direction in pairs({ left = "l", right = "r", up = "u", down = "d" }) do
    command("SUPER + " .. key, "hyprctl dispatch movefocus " .. direction)
end

for workspace = 1, 10 do
    local key = tostring(workspace % 10)
    command("SUPER + " .. key, "hyprctl dispatch workspace " .. workspace)
    command("SUPER + SHIFT + " .. key, "hyprctl dispatch movetoworkspace " .. workspace)
end

command("SUPER + SHIFT + right", "hyprctl dispatch resizeactive 20 0", { repeating = true })
command("SUPER + SHIFT + left", "hyprctl dispatch resizeactive -20 0", { repeating = true })
command("SUPER + SHIFT + up", "hyprctl dispatch resizeactive 0 -20", { repeating = true })
command("SUPER + SHIFT + down", "hyprctl dispatch resizeactive 0 20", { repeating = true })

command("XF86AudioRaiseVolume", "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+", { repeating = true, locked = true })
command("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", { repeating = true, locked = true })
command("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true })
command("XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", { locked = true })
command("XF86MonBrightnessUp", "brightnessctl s 10%+", { repeating = true })
command("XF86MonBrightnessDown", "brightnessctl s 10%-", { repeating = true })
command("XF86AudioNext", "playerctl next", { locked = true })
command("XF86AudioPause", "playerctl play-pause", { locked = true })
command("XF86AudioPlay", "playerctl play-pause", { locked = true })
command("XF86AudioPrev", "playerctl previous", { locked = true })
