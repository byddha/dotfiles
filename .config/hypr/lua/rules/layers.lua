local rules = {
    { match = { namespace = "hyprwhichkey" }, blur = true },
    { match = { namespace = "rofi" },         animation = "slide" },
    { match = { namespace = "vicinae" },      animation = "popin 90%" },
    { match = { namespace = "bidshell:.*" },  no_anim = true },
    { match = { namespace = "hyprpicker" },   no_anim = true }
}

for _, rule in ipairs(rules) do
    hl.layer_rule(rule)
end
