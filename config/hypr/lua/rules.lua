local version = tostring(hl.version())
local major, minor = version:match("^[vV]?(%d+)%.(%d+)")
local nested_rule_effect = major and (tonumber(major) > 0 or tonumber(minor) >= 57) or false

local function make_rule(match, effects)
    local rule = { match = match }
    if nested_rule_effect then
        rule.effect = effects
    else
        for key, value in pairs(effects) do
            rule[key] = value
        end
    end
    return rule
end

for _, namespace in ipairs({ "wofi", "swaync-control-center", "swaync-notification-window", "gtklock" }) do
    hl.layer_rule(make_rule(
        { namespace = namespace },
        { blur = true, ignore_alpha = 0.3, blur_popups = true }
    ))
end

for _, class in ipairs({ "^(pavucontrol)$", "^(blueman-manager)$", "^(nm-connection-editor)$", "^(swappy)$" }) do
    hl.window_rule(make_rule({ class = class }, { float = true, center = true }))
end
