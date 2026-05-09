local settings    = require("lua.core.settings")
local monitors    = settings.monitors

local profiles    = {}

profiles.desktop  = {
    { workspace = "1", monitor = monitors.main, default = true },
    { workspace = "2", monitor = monitors.main },
    { workspace = "3", monitor = monitors.main },
    { workspace = "4", monitor = monitors.main },
    { workspace = "5", monitor = monitors.main },
    { workspace = "6", monitor = monitors.mini, default = true },
    { workspace = "7", monitor = monitors.mini },
    { workspace = "8", monitor = monitors.mini },
}

profiles.notebook = {
    { workspace = "1", monitor = monitors.builtin },
    { workspace = "2", monitor = monitors.builtin },
    { workspace = "3", monitor = monitors.builtin },
    { workspace = "4", monitor = monitors.builtin },
    { workspace = "5", monitor = monitors.builtin },
}

local workspaces  = settings.profile_from(profiles)

for _, workspace in ipairs(workspaces) do
    hl.workspace_rule(workspace)
end

hl.workspace_rule({ workspace = "special:chatapps", layout = "scrolling" })
