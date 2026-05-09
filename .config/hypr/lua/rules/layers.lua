local rules = {
    { match = { namespace = "hyprwhichkey" },               blur = true },
    { match = { namespace = "rofi" },                       animation = "slide" },
    { match = { namespace = "walker" },                     animation = "slide bottom" },
    { match = { namespace = "bidshell:overview" },          no_anim = true },
    { match = { namespace = "bidshell:gamelauncher" },      no_anim = true },
    { match = { namespace = "bidshell:regionselector" },    no_anim = true },
    { match = { namespace = "bidshell:shutdown-reminder" }, no_anim = true },
}

for _, rule in ipairs(rules) do
    hl.layer_rule(rule)
end
