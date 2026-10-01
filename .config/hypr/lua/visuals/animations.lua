hl.config({
    animations = {
        enabled = true,
    },
})

local curves = {
    easeOutQuint    = { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } },
    linear          = { type = "bezier", points = { { 0, 0 }, { 1, 1 } } },
    almostLinear    = { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } },
    quick           = { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } },
    easy            = { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 },
    snappy          = { type = "spring", mass = 1, stiffness = 500, dampening = 35 },
    emphasizedDecel = { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } },
    menu_decel      = { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } },
    menu_accel      = { type = "bezier", points = { { 0.52, 0.03 }, { 0.72, 0.08 } } },
    stall           = { type = "bezier", points = { { 1, -0.1 }, { 0.7, 0.85 } } },
}

for name, curve in pairs(curves) do
    hl.curve(name, curve)
end

local animations = {
    { leaf = "global",           enabled = true, speed = 10,   bezier = "default" },
    { leaf = "border",           enabled = true, speed = 5.39, bezier = "easeOutQuint" },
    { leaf = "windows",          enabled = true, speed = 4.79, spring = "easy" },
    { leaf = "windowsIn",        enabled = true, speed = 4.1,  spring = "snappy",       style = "popin 87%" },
    { leaf = "windowsOut",       enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" },
    { leaf = "fadeIn",           enabled = true, speed = 1.73, bezier = "almostLinear" },
    { leaf = "fadeOut",          enabled = true, speed = 1.46, bezier = "almostLinear" },
    { leaf = "fade",             enabled = true, speed = 3.03, bezier = "quick" },
    { leaf = "layersIn",         enabled = true, speed = 2.7,  bezier = "emphasizedDecel", style = "popin 93%" },
    { leaf = "layersOut",        enabled = true, speed = 2.4,  bezier = "menu_accel",   style = "popin 94%" },
    { leaf = "fadeLayersIn",     enabled = true, speed = 0.5,  bezier = "menu_decel" },
    { leaf = "fadeLayersOut",    enabled = true, speed = 2.7,  bezier = "stall" },
    { leaf = "workspaces",       enabled = true, speed = 1.2,  bezier = "almostLinear", style = "fade" },
    { leaf = "workspacesIn",     enabled = true, speed = 0.75, bezier = "almostLinear", style = "fade" },
    { leaf = "specialWorkspace", enabled = true, speed = 0.5,  bezier = "almostLinear", style = "fade" },
    { leaf = "zoomFactor",       enabled = true, speed = 7,    bezier = "quick" },
}

for _, animation in ipairs(animations) do
    hl.animation(animation)
end
