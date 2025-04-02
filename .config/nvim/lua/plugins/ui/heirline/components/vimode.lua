local utils = require "heirline.utils"
local surrounds = require "plugins.ui.heirline.surrounds"

local ViMode = {
    init = function(self)
        self.mode = vim.fn.mode(1)
    end,
    static = {
        mode_names = {
            n = "NORMAL",
            no = "NORMAL",
            nov = "NORMAL",
            noV = "NORMAL",
            ["no\22"] = "NORMAL",
            niI = "NORMAL",
            niR = "NORMAL",
            niV = "NORMAL",
            nt = "NTERMINAL",
            ntT = "NTERMINAL",

            v = "VISUAL",
            vs = "VISUAL",
            V = "VISUAL",
            Vs = "VISUAL",

            ["\22"] = "VISUAL",
            ["\22s"] = "VISUAL",

            s = "SELECT",
            S = "SELECT",
            ["\19"] = "SELECT",

            i = "INSERT",
            ic = "INSERT",
            ix = "INSERT",

            R = "REPLACE",
            Rc = "REPLACE",
            Rx = "REPLACE",
            Rv = "REPLACE",
            Rvc = "REPLACE",
            Rvx = "REPLACE",

            c = "COMMAND",
            cv = "COMMAND",
            ce = "COMMAND",
            cr = "COMMAND",

            r = "PROMPT",
            rm = "PROMPT",

            ["r?"] = "CONFIRM",
            ["!"] = "SHELL",
            t = "TERMINAL",
        },
    },
    provider = function(self)
        return "  " .. self.mode_names[self.mode] .. " "
    end,
    hl = function(_)
        return { fg = "bright_bg", bold = true }
    end,
    update = {
        "ModeChanged",
        pattern = "*:*",
        callback = vim.schedule_wrap(function()
            vim.cmd "redrawstatus"
        end),
    },
}

return utils.surround(
    { "", surrounds.slope.right },
    "bright_fg",
    utils.surround({ "", surrounds.slope.right }, "purple", ViMode)
)
