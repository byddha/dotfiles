local helpers = require("lua.binds.helpers")

-- left-hand-only launcher: vicinae hardcodes Enter for the primary action, so Tab is
-- remapped to it, only while the launcher layer is open
local binds = {
    helpers.bind("TAB", helpers.exec("wtype -k Return")),
    helpers.bind("<S-TAB>", helpers.exec("wtype -M shift -k Return -m shift")),
}

local function set_enabled(enabled)
    for _, keybind in ipairs(binds) do
        keybind:set_enabled(enabled)
    end
end

set_enabled(false)

hl.on("layer.opened", function(layer)
    if layer.namespace == "vicinae" then
        set_enabled(true)
    end
end)

hl.on("layer.closed", function(layer)
    if layer.namespace == "vicinae" then
        set_enabled(false)
    end
end)
