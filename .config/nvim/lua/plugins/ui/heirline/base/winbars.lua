local conditions = require "heirline.conditions"
local utils = require "heirline.utils"
local surrounds = require "plugins.ui.heirline.surrounds"

local Space = {
    provider = " ",
}
local Align = {
    provider = "%=",
}

local FileNameBlock = require "plugins.ui.heirline.components.filename"

local Fn = {
    fallthrough = false,
    {
        condition = function()
            return conditions.buffer_matches { buftype = { "terminal" } }
        end,
        init = function()
            vim.opt_local.winbar = nil
        end,
    },
    {
        condition = function()
            return not conditions.is_active()
        end,
        utils.surround(
            { surrounds.half_circles.left, surrounds.half_circles.right },
            "bright_bg",
            { hl = { fg = "gray", force = true }, FileNameBlock }
        ),
    },
    utils.surround({ surrounds.half_circles.left, surrounds.half_circles.right }, "bright_bg", FileNameBlock),
}

return {
    Fn,
    Space,
    require "plugins.ui.heirline.components.navic",
    Align,
}
