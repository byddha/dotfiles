local opt = vim.opt
local o = vim.o
local g = vim.g

-- {{{ General Settings
o.termguicolors = true
o.laststatus = 3
o.showmode = false
o.clipboard = "unnamedplus"
o.cursorline = true
o.cursorlineopt = "number"
o.ignorecase = true
o.smartcase = true
o.mouse = "a"
o.timeoutlen = 400
o.updatetime = 250

o.signcolumn = "yes"
vim.o.showtabline = 2
o.splitbelow = true
o.splitright = true
o.undofile = true
o.relativenumber = true

o.number = true
o.numberwidth = 2
o.ruler = false
-- }}}

-- {{{ Indentation Settings
o.smartindent = true
o.tabstop = 4
o.expandtab = true
o.softtabstop = 4
o.shiftwidth = 4
-- }}}

-- {{{ Visual Settings
opt.fillchars:append { eob = " ", diff = "╱" }
opt.shortmess:append "sI"
opt.whichwrap:append "<>[]hl"
-- }}}

-- {{{ Disable Default Providers
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
-- }}}

-- {{{ Mason.nvim Path Setup
local is_windows = require("helpers").is_windows()
local sep = is_windows and "\\" or "/"
local delim = is_windows and ";" or ":"

local mason_bin_path = vim.fn.stdpath "data" .. sep .. "mason" .. sep .. "bin"
vim.env.PATH = mason_bin_path .. delim .. vim.env.PATH
vim.o.shell = "zsh"
-- }}}

-- {{{ Windows-Specific Shell Settings
if is_windows then
    vim.o.shell = vim.fn.executable "pwsh" == 1 and "pwsh" or "powershell"
    vim.o.shellcmdflag =
        "-NoLogo -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();$PSDefaultParameterValues['Out-File:Encoding']='utf8';"
    vim.o.shellredir = '2>&1 | %{ "$_" } | Out-File %s; exit $LastExitCode'
    vim.o.shellpipe = '2>&1 | %{ "$_" } | Tee-Object %s; exit $LastExitCode'
    vim.o.shellquote = ""
    vim.o.shellxquote = ""
end
-- }}}

-- {{{ Clipboard Support for WezTerm SSH
if os.getenv "SSH_CLIENT" or os.getenv "SSH_TTY" then
    local function my_paste(_)
        return function(_)
            return vim.split(vim.fn.getreg '"', "\n")
        end
    end

    vim.g.clipboard = {
        name = "OSC 52",
        copy = {
            ["+"] = require("vim.ui.clipboard.osc52").copy "+",
            ["*"] = require("vim.ui.clipboard.osc52").copy "*",
        },
        paste = {
            ["+"] = my_paste "+",
            ["*"] = my_paste "*",
        },
    }
end
-- }}}

-- {{{ Autocommands
vim.cmd [[
    autocmd FileType * set formatoptions-=cro
    autocmd FileType * setlocal formatoptions-=cro
]]
-- }}}

-- Hypr
vim.filetype.add {
    pattern = { [".*/hypr/.*%.conf"] = "hyprlang" },
}
