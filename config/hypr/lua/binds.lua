local function command(keys, cmd, flags)
    hl.bind(keys, hl.dsp.exec_cmd(cmd), flags or {})
end

local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local scripts = config_home .. "/scripts/"

local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

command("SUPER + T", "bash " .. shell_quote(scripts .. "terminal-launch.sh"))
command("SUPER + E", "thunar")
command("SUPER + SPACE", "wofi --show drun")
command("SUPER + B", "xdg-open https://")
command("SUPER + A", "pavucontrol")
command("SUPER + L", scripts .. "lock.sh")
command("SUPER + N", "swaync-client -t -s")

hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + M", hl.dsp.exit())
hl.bind("SUPER + F", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.center())
end)
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))

command("SUPER + SHIFT + L", scripts .. "wofi-power.sh")
command("SUPER + SHIFT + S", scripts .. "wofi-screenshot.sh")
command("SUPER + SHIFT + T", scripts .. "wofi-theme.sh")
command("SUPER + V", scripts .. "wofi-clipboard.sh")
command("SUPER + SHIFT + W", scripts .. "wofi-wallpaper.sh")

for key, direction in pairs({ left = "l", right = "r", up = "u", down = "d" }) do
    hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = direction }))
end

for workspace = 1, 10 do
    local key = tostring(workspace % 10)
    local workspace_name = tostring(workspace)
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace_name }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace_name }))
end

hl.bind("SUPER + SHIFT + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

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
