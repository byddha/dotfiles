local utils = require "heirline.utils"
local surrounds = require "plugins.ui.heirline.surrounds"

local CwdIcon = {
    init = function(self)
        self.icon = " "
    end,
    hl = {
        bg = "blue",
        bold = true,
        fg = "bright_bg",
    },

    flexible = 2,

    {
        provider = function(self)
            return self.icon
        end,
    },

    {
        provider = "",
    },
}

local CwdText = {
    init = function(self)
        local cwd = vim.fn.getcwd(0)
        self.cwd = vim.fn.fnamemodify(cwd, ":~"):gsub("\\", "/")
    end,
    hl = {
        bg = "bright_bg",
        fg = "blue",
    },

    flexible = 1,

    {
        provider = function(self)
            return self.cwd
        end,
    },
    {
        provider = function(self)
            local cwd = vim.fn.fnamemodify(self.cwd, ":t")
            return cwd
        end,
    },
    {
        provider = "",
    },
}

return utils.surround({ surrounds.half_circles.left, "" }, "blue", {
    CwdIcon,
    utils.surround({ surrounds.half_circles.left, "" }, "bright_bg", CwdText),
})
