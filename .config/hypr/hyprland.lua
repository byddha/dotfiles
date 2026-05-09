local modules = {
    "lua.env",
    "lua.displays.monitors",
    "lua.displays.workspaces",
    "lua.visuals.appearance",
    "lua.layout.tiling",
    "lua.visuals.animations",
    "lua.rules.layers",
    "lua.input.controls",
    "lua.rules.windows",
    "lua.binds.keybinds",
    "lua.binds.submaps",
    "lua.startup.autostart",
}

for _, module in ipairs(modules) do
    require(module)
end
