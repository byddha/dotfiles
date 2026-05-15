local rules = {
    { match = { namespace = "hyprwhichkey" }, blur = true },
    { match = { namespace = "rofi" },         animation = "slide" },
    { match = { namespace = "walker" },       animation = "slide bottom" },
    { match = { namespace = "bidshell:.*" },  no_anim = true }
}

for _, rule in ipairs(rules) do
    hl.layer_rule(rule)
end
