local conditions = require "heirline.conditions"
local utils = require "heirline.utils"
local shared = require "plugins.ui.heirline.shared"

local Space, Align = shared.Space, shared.Align

local ViMode = utils.surround(
    { "", shared.SLOPE_RIGHT },
    "bright_fg",
    utils.surround({ "", shared.SLOPE_RIGHT }, "purple", {
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
            return "  " .. self.mode_names[vim.fn.mode(1)] .. " "
        end,
        hl = { fg = "bright_bg", bold = true },
        update = {
            "ModeChanged",
            pattern = "*:*",
            callback = vim.schedule_wrap(function()
                vim.cmd "redrawstatus"
            end),
        },
    })
)

local Git = {
    condition = conditions.is_git_repo,

    init = function(self)
        self.status_dict = vim.b.gitsigns_status_dict
        self.has_changes = self.status_dict.added and self.status_dict.added ~= 0
            or self.status_dict.removed and self.status_dict.removed ~= 0
            or self.status_dict.changed and self.status_dict.changed ~= 0
    end,

    hl = { fg = "orange" },

    {
        provider = function(self)
            return " " .. self.status_dict.head
        end,
        hl = { bold = true },
    },
    {
        condition = function(self)
            return self.has_changes
        end,
        provider = " (",
    },
    {
        provider = function(self)
            local count = self.status_dict.added or 0
            return count > 0 and ("  " .. count)
        end,
        hl = { fg = "git_add" },
    },
    {
        provider = function(self)
            local count = self.status_dict.removed or 0
            return count > 0 and ("  " .. count)
        end,
        hl = { fg = "git_del" },
    },
    {
        provider = function(self)
            local count = self.status_dict.changed or 0
            return count > 0 and ("  " .. count)
        end,
        hl = { fg = "git_change" },
    },
    {
        condition = function(self)
            return self.has_changes
        end,
        provider = " ) ",
    },
}

local PYTHON_FILES = {
    ["pyproject.toml"] = true,
    ["setup.cfg"] = true,
    ["requirements.txt"] = true,
    ["Pipfile"] = true,
    ["tox.ini"] = true,
    ["uv.lock"] = true,
}

local PythonEnv = {
    condition = function()
        return vim.bo.filetype == "python"
            or PYTHON_FILES[vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")] == true
    end,

    provider = function()
        local ok, venv_selector = pcall(require, "venv-selector")
        if not ok then
            return ""
        end

        local source = venv_selector.source()
        local python = venv_selector.python()

        if python and python ~= "" then
            if source and source ~= "" then
                return " " .. source .. ":" .. python
            end
            return " " .. python
        end

        local venv_path = vim.env.VIRTUAL_ENV
        if venv_path and venv_path ~= "" then
            return " " .. venv_path .. "/bin/python"
        end

        return " System"
    end,

    hl = { fg = "green", bold = true },
}

local CsharpEnv = {
    condition = function()
        if vim.bo.filetype == "cs" then
            return true
        end
        local name = vim.api.nvim_buf_get_name(0)
        return name:match "%.csproj$" ~= nil or name:match "%.sln$" ~= nil
    end,

    provider = function()
        local solution = vim.g.roslyn_nvim_selected_solution
        if solution and solution ~= "" then
            return "󰌛 " .. vim.fn.fnamemodify(solution, ":t:r")
        end
        return ""
    end,

    hl = { fg = "purple", bold = true },
}

local LanguageEnv = {
    fallthrough = false,
    PythonEnv,
    CsharpEnv,
}

local MacroRec = {
    condition = function()
        return vim.fn.reg_recording() ~= "" and vim.o.cmdheight == 0
    end,
    update = { "RecordingEnter", "RecordingLeave" },
    provider = " Rec => ",
    hl = { fg = "orange", bold = true },
    utils.surround({ "[", "]" }, nil, {
        provider = function()
            return vim.fn.reg_recording()
        end,
        hl = { fg = "green", bold = true },
    }),
}

local DapMessages = {
    condition = function()
        return require("dap").session() ~= nil
    end,
    provider = function()
        return " " .. require("dap").status()
    end,
    hl = "Debug",
}

local FileEncoding = {
    provider = function()
        local enc = (vim.bo.fenc ~= "" and vim.bo.fenc) or vim.o.enc
        return enc:upper()
    end,
}

local Diagnostics = {
    condition = conditions.has_diagnostics,
    update = { "DiagnosticChanged", "BufEnter" },

    static = {
        error_icon = " ",
        warn_icon = " ",
        info_icon = "󰋼 ",
        hint_icon = "󰛩 ",
    },

    init = function(self)
        self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
        self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
        self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
        self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
    end,

    {
        provider = function(self)
            return self.errors > 0 and (self.error_icon .. self.errors .. " ")
        end,
        hl = { fg = "diag_error" },
    },
    {
        provider = function(self)
            return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
        end,
        hl = { fg = "diag_warn" },
    },
    {
        provider = function(self)
            return self.info > 0 and (self.info_icon .. self.info .. " ")
        end,
        hl = { fg = "diag_info" },
    },
    {
        provider = function(self)
            return self.hints > 0 and (self.hint_icon .. self.hints)
        end,
        hl = { fg = "diag_hint" },
    },
}

local LspActive = {
    condition = conditions.lsp_attached,
    update = { "LspAttach", "LspDetach" },

    provider = function()
        local names = {}
        for _, server in pairs(vim.lsp.get_clients { bufnr = 0 }) do
            table.insert(names, server.name)
        end
        return " [" .. table.concat(names, " ") .. "]"
    end,
    hl = { fg = "green", bold = true },
}

local WorkDir = utils.surround({ shared.LEFT_CAP, "" }, "blue", {
    {
        flexible = 2,
        hl = { bg = "blue", fg = "bright_bg", bold = true },
        { provider = " " },
        { provider = "" },
    },
    utils.surround({ shared.LEFT_CAP, "" }, "bright_bg", {
        init = function(self)
            self.cwd = vim.fn.fnamemodify(vim.fn.getcwd(0), ":~"):gsub("\\", "/")
        end,
        flexible = 1,
        hl = { bg = "bright_bg", fg = "blue" },
        {
            provider = function(self)
                return self.cwd
            end,
        },
        {
            provider = function(self)
                return vim.fn.fnamemodify(self.cwd, ":t")
            end,
        },
        { provider = "" },
    }),
})

local ScrollBar = utils.surround({ shared.LEFT_CAP, "" }, "diag_warn", {
    { provider = " ", hl = { fg = "bright_bg" } },
    utils.surround({ shared.LEFT_CAP, "" }, "bright_bg", {
        provider = function()
            local curr_line = vim.api.nvim_win_get_cursor(0)[1]
            local total_lines = vim.api.nvim_buf_line_count(0)
            local percentage = total_lines <= 1 and 100
                or math.floor(((curr_line - 1) / (total_lines - 1)) * 100)
            return string.format("%3d%%%%", percentage)
        end,
        hl = { fg = "diag_warn", bg = "bright_bg" },
    }),
})

local FileType = {
    provider = function()
        return vim.bo.filetype:upper()
    end,
    hl = function()
        return { fg = utils.get_highlight("Type").fg, bold = true }
    end,
}

local SpecialStatusline = {
    condition = function()
        return conditions.buffer_matches {
            buftype = { "nofile", "prompt", "help", "quickfix" },
            filetype = { "^git.*", "fugitive" },
        }
    end,

    FileType,
    Space,
    {
        condition = function()
            return vim.bo.filetype == "help"
        end,
        provider = function()
            return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
        end,
        hl = { fg = "blue" },
    },
    Align,
}

local TerminalStatusline = {
    condition = function()
        return conditions.buffer_matches { buftype = { "terminal" } }
    end,

    ViMode,
    Space,
    FileType,
    Space,
    {
        provider = function()
            local name = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
            return " " .. name
        end,
        hl = { fg = "blue", bold = true },
    },
    Align,
}

local DefaultStatusline = {
    ViMode,
    Space,
    Git,
    Space,
    LanguageEnv,
    Align,
    --
    MacroRec,
    Space,
    DapMessages,
    Align,
    --
    FileEncoding,
    Space,
    Diagnostics,
    Space,
    LspActive,
    Space,
    WorkDir,
    Space,
    ScrollBar,
}

return {
    hl = function()
        return conditions.is_active() and "StatusLine" or "StatusLineNC"
    end,

    fallthrough = false,

    SpecialStatusline,
    TerminalStatusline,
    DefaultStatusline,
}
