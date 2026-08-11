local M = {}

M.LEFT_CAP = ""
M.RIGHT_CAP = ""
M.SLOPE_RIGHT = ""

M.Space = { provider = " " }
M.Align = { provider = "%=" }

-- Expects an ancestor component to have set `self.filename`.
M.FileIcon = {
    init = function(self)
        self.icon, self.icon_color = require("nvim-web-devicons").get_icon_color(
            self.filename,
            vim.fn.fnamemodify(self.filename, ":e"),
            { default = true }
        )
    end,
    provider = function(self)
        return self.icon and (self.icon .. " ")
    end,
    hl = function(self)
        return { fg = self.icon_color }
    end,
}

return M
