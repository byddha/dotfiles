local Align = { provider = "%=" }
local Space = { provider = " " }

local conditions = require "heirline.conditions"

local SpecialStatusline = {
    condition = function()
        return conditions.buffer_matches {
            buftype = { "nofile", "prompt", "help", "quickfix" },
            filetype = { "^git.*", "fugitive" },
        }
    end,

    require "plugins.ui.heirline.components.filetype",
    Space,
    require "plugins.ui.heirline.components.helpfilename",
    Align,
}

local TerminalStatusline = {
    condition = function()
        return conditions.buffer_matches { buftype = { "terminal" } }
    end,

    require "plugins.ui.heirline.components.vimode",
    Space,
    require "plugins.ui.heirline.components.filetype",
    Space,
    require "plugins.ui.heirline.components.termname",
    Align,
}

local DefaultStatusline = {
    require "plugins.ui.heirline.components.vimode",
    Space,
    require "plugins.ui.heirline.components.git",
    Align,
    --
    require "plugins.ui.heirline.components.macrorec",
    Space,
    require "plugins.ui.heirline.components.dapmessages",
    Align,
    --
    require "plugins.ui.heirline.components.fileencoding",
    Space,
    require "plugins.ui.heirline.components.diagnostics",
    Space,
    require "plugins.ui.heirline.components.lspactive",
    Space,
    require "plugins.ui.heirline.components.workdir",
    Space,
    require "plugins.ui.heirline.components.scrollbar",
}

return {
    hl = function()
        if conditions.is_active() then
            return "StatusLine"
        else
            return "StatusLineNC"
        end
    end,

    fallthrough = false,

    SpecialStatusline,
    TerminalStatusline,
    DefaultStatusline,
}
