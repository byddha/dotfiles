local util = require "lspconfig.util"
local merge = require("helpers").merge
local is_windows = require("helpers").is_windows

local config = {
    force_setup = true,
    single_file_support = false,
    root_dir = util.root_pattern("project.godot", ".git"),
    filetypes = { "gd", "gdscript", "gdscript3" },
}
if is_windows() then
    config = merge(config, {
        cmd = { "ncat", "127.0.0.1", "6005" },
    })
end

return config
