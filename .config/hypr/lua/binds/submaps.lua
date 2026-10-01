local settings          = require("lua.core.settings")
local helpers           = require("lua.binds.helpers")

local bind              = helpers.bind
local dar               = helpers.dispatch_and_reset
local ear               = helpers.exec_and_reset

local window_mode_binds = {
    { "n",        dar(hl.dsp.window.float({ action = "toggle" })), "Float" },
    { "p",        dar(hl.dsp.window.pin()),                        "Pin" },
    { "f",        dar(hl.dsp.window.fullscreen()),                 "Fullscreen" },
    { "g",        dar(hl.dsp.group.toggle()),                      "Group" },
    { "TAB",      hl.dsp.group.next(),                             "Cycle group", { repeating = true } },
    { "escape",   hl.dsp.submap("reset") },
    { "catchall", hl.dsp.submap("reset") },
}

local toggle_binds      = {
    { "d",        ear(settings.script("discord.sh")), "Toggle discord zoom" },
    { "escape",   hl.dsp.submap("reset") },
    { "catchall", hl.dsp.submap("reset") },
}

local submaps           = {
    { name = "window-mode", binds = window_mode_binds },
    { name = "toggles",     binds = toggle_binds },
}

for _, submap in ipairs(submaps) do
    hl.define_submap(submap.name, function()
        for _, spec in ipairs(submap.binds) do
            bind(spec)
        end
    end)
end
