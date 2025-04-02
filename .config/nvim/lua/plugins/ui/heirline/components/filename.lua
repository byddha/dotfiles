local utils = require "heirline.utils"

local FileNameBase = {
    init = function(self)
        self.filename = vim.api.nvim_buf_get_name(0)
    end,
}

local FileIcon = require("plugins.ui.heirline.components.fileicon")

local FileName = {
    init = function(self)
        self.lfilename = vim.fn.fnamemodify(self.filename, ":t")
        if self.lfilename == "" then
            self.lfilename = "[No Name]"
        end
    end,
    hl = { fg = utils.get_highlight("Directory").fg },
    provider = function(self)
        return self.lfilename
    end,
}

local FileFlags = {
    {
        condition = function()
            return vim.bo.modified
        end,
        provider = "  ",
        hl = {
            fg = "git_add",
        },
    },
    {
        condition = function()
            return not vim.bo.modifiable or vim.bo.readonly
        end,
        provider = "  ",
        hl = {
            fg = "purple",
        },
    },
}

local FileNameModifier = {
    hl = function()
        if vim.bo.modified then
            return {
                fg = "cyan",
                bold = true,
                force = true,
            }
        end
    end,
}

return utils.insert(FileNameBase, FileIcon, utils.insert(FileNameModifier, FileName), FileFlags, {
    provider = "%<",
})
