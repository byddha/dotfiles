hl.config({
    animations = {
        enabled = true,
    },
})

local curves = {
    wind          = { { 0.05, 0.85 }, { 0.03, 0.97 } },
    winIn         = { { 0.07, 0.88 }, { 0.04, 0.99 } },
    winOut        = { { 0.20, -0.15 }, { 0, 1 } },
    liner         = { { 1, 1 }, { 1, 1 } },
    md3_standard  = { { 0.12, 0 }, { 0, 1 } },
    md3_decel     = { { 0.05, 0.80 }, { 0.10, 0.97 } },
    md3_accel     = { { 0.20, 0 }, { 0.80, 0.08 } },
    overshot      = { { 0.05, 0.85 }, { 0.07, 1.04 } },
    crazyshot     = { { 0.1, 1.22 }, { 0.68, 0.98 } },
    hyprnostretch = { { 0.05, 0.82 }, { 0.03, 0.94 } },
    menu_decel    = { { 0.05, 0.82 }, { 0, 1 } },
    menu_accel    = { { 0.20, 0 }, { 0.82, 0.10 } },
    easeInOutCirc = { { 0.78, 0 }, { 0.15, 1 } },
    easeOutCirc   = { { 0, 0.48 }, { 0.38, 1 } },
    easeOutExpo   = { { 0.10, 0.94 }, { 0.23, 0.98 } },
    softAcDecel   = { { 0.20, 0.20 }, { 0.15, 1 } },
    md2           = { { 0.30, 0 }, { 0.15, 1 } },
    OutBack       = { { 0.28, 1.40 }, { 0.58, 1 } },
}

for name, points in pairs(curves) do
    hl.curve(name, { type = "bezier", points = points })
end

local animations = {
    { leaf = "border",           enabled = true, speed = 1.6, bezier = "liner" },
    { leaf = "windowsOut",       enabled = true, speed = 2.8, bezier = "easeOutCirc" },
    { leaf = "fade",             enabled = true, speed = 1.8, bezier = "md3_decel" },
    { leaf = "layersOut",        enabled = true, speed = 1.5, bezier = "menu_accel" },
    { leaf = "fadeLayersIn",     enabled = true, speed = 1.6, bezier = "menu_decel" },
    { leaf = "fadeLayersOut",    enabled = true, speed = 1.8, bezier = "menu_accel" },
    { leaf = "layersIn",         enabled = true, speed = 1.8, bezier = "menu_decel", style = "slide" },
    { leaf = "windowsMove",      enabled = true, speed = 3.0, bezier = "wind",       style = "slide" },
    { leaf = "borderangle",      enabled = true, speed = 82,  bezier = "liner",      style = "loop" },
    { leaf = "windowsIn",        enabled = true, speed = 3.2, bezier = "winIn",      style = "slide" },
    { leaf = "workspaces",       enabled = true, speed = 4.0, bezier = "menu_decel", style = "slidevert" },
    { leaf = "specialWorkspace", enabled = true, speed = 2.3, bezier = "md3_decel",  style = "slidefadevert 15%" },
}

for _, animation in ipairs(animations) do
    hl.animation(animation)
end
