for _, namespace in ipairs({ "wofi", "swaync-control-center", "swaync-notification-window", "gtklock" }) do
    hl.layer_rule({
        match = { namespace = namespace },
        effect = {
            blur = true,
            ignore_alpha = 0.3,
            blur_popups = true,
        },
    })
end

for _, class in ipairs({ "^(pavucontrol)$", "^(blueman-manager)$", "^(nm-connection-editor)$", "^(swappy)$" }) do
    hl.window_rule({
        match = { class = class },
        effect = {
            float = true,
            center = true,
        },
    })
end
