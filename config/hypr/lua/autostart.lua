hl.on("hyprland.start", function()
    local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
    hl.exec_cmd(config_home .. "/scripts/session-init.sh")
end)
