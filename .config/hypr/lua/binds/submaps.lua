local settings          = require("lua.core.settings")
local helpers           = require("lua.binds.helpers")
local programs          = settings.programs

local bind              = helpers.bind
local dar               = helpers.dispatch_and_reset
local ear               = helpers.exec_and_reset

local app_binds         = {
    { "z",      ear("zen-browser"),                                                                                                    "Browser" },
    { "<S-w>",  ear("thunar"),                                                                                                         "Thunar" },
    { "w",      ear('kitty --title "Yazi" yazi'),                                                                                      "Yazi" },
    { "d",      ear(programs.launch .. ' -ic "vesktop" dev.vencord.Vesktop'),                                                          "Discord" },
    { "s",      ear(programs.launch .. ' -ic "steam" steam'),                                                                          "Steam" },
    { "t",      ear(programs.launch .. ' -it "teams.cloud.microsoft_/" gio launch ~/.local/share/applications/webapp-teams.desktop'),  "Teams", },
    { "TAB",    dar(hl.dsp.focus({ workspace = "previous" })),                                                                         "Back" },
    { "escape", hl.dsp.submap("reset") },
}

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
    { name = "apps",        binds = app_binds },
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
