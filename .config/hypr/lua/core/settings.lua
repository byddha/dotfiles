local helpers  = require("lua.core.helpers")
local machines = require("lua.core.machines")

local M        = {}

local home     = assert(os.getenv("HOME"), "HOME is not set")
local hostname = helpers.read_line("/proc/sys/kernel/hostname", "hostname file was empty")

M.home         = home
M.hypr_dir     = home .. "/dotfiles/.config/hypr"
M.main_mod     = "SUPER"

M.programs     = {
    terminal     = "ghostty",
    file_manager = "krusader",
    launch       = home .. "/dotfiles/.config/hypr/scripts/run_or_focus.sh",
}

local local_config = machines.for_hostname(hostname)
M.default_local    = local_config
M.local_config     = local_config
M.monitors         = local_config.monitors or {}
M.touch_output     = local_config.touch_output or M.monitors.mini

function M.script(name)
    return M.hypr_dir .. "/scripts/" .. name
end

function M.cmd(parts)
    return table.concat(parts, " ")
end

function M.profile_from(profiles)
    local name = assert(M.local_config.profile, "profile is not set")
    local profile = profiles[name]

    if not profile then
        error("unknown profile: " .. name)
    end

    return profile
end

return M
