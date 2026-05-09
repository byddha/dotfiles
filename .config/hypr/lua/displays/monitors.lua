local settings = require("lua.core.settings")
local monitors = settings.monitors

local profiles = {}

profiles.desktop = {
    monitors = {
        {
            output        = monitors.main,
            mode          = "highres highrr",
            position      = "0x0",
            scale         = 1.0,
            bitdepth      = 10,
            sdrbrightness = 1.2,
            sdrsaturation = 1.2,
            cm            = "srgb",
        },
        {
            output       = monitors.mini,
            mode         = "preferred",
            scale        = 1.2,
            position     = "auto-center-down",
            supports_hdr = -1,
        },
    },
}

profiles.notebook = {
    monitors = {
        {
            output   = monitors.builtin,
            mode     = "2880x1800@60.0",
            position = "0x0",
            scale    = 1.5,
            bitdepth = 10,
            vrr      = 1,
            cm       = "srgb",
        },
    },
}

local profile = settings.profile_from(profiles)

for _, monitor in ipairs(profile.monitors) do
    hl.monitor(monitor)
end
