local utils = require "heirline.utils"
local surrounds = require "plugins.ui.heirline.surrounds"

local ScrollBarIcon = {
    provider = function()
        return "" .. " "
    end,
    hl = { fg = "bright_bg" },
}

local ScrollBarText = {
    provider = function()
        local curr_line = vim.api.nvim_win_get_cursor(0)[1]
        local total_lines = vim.api.nvim_buf_line_count(0)
        local scroll_percentage

        if total_lines <= 1 then
            scroll_percentage = 100
        else
            scroll_percentage = math.floor(((curr_line - 1) / (total_lines - 1)) * 100)
        end

        return string.format("%3d%%%%", scroll_percentage)
    end,
    hl = { fg = "diag_warn", bg = "bright_bg" },
}

return utils.surround({ surrounds.half_circles.left, "" }, "diag_warn", {
    ScrollBarIcon,
    utils.surround({ surrounds.half_circles.left, "" }, "bright_bg", ScrollBarText),
})
