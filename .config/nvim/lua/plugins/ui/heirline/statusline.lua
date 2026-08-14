local conditions = require "heirline.conditions"
local shared = require "plugins.ui.heirline.shared"
local repo = require "plugins.ui.heirline.git"
local activity = require "plugins.ui.heirline.activity"

local ViMode = {
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
        return " " .. self.mode_names[vim.fn.mode(1)]
    end,
    update = {
        "ModeChanged",
        pattern = "*:*",
        callback = vim.schedule_wrap(function()
            vim.cmd "redrawstatus"
        end),
    },
}

local Git = {
    condition = function()
        return repo.head ~= nil
    end,

    on_click = {
        name = "heirline_git",
        callback = function(_, _, _, button)
            if button == "r" then
                Snacks.lazygit()
            else
                vim.cmd "CodeDiff"
            end
        end,
    },

    {
        provider = function()
            return " " .. shared.literal(repo.head)
        end,
    },
    {
        provider = function()
            return repo.insertions > 0 and ("  " .. repo.insertions)
        end,
        hl = { fg = "git_add" },
    },
    {
        provider = function()
            return repo.deletions > 0 and ("  " .. repo.deletions)
        end,
        hl = { fg = "git_del" },
    },
    {
        provider = function()
            return repo.untracked > 0 and ("  " .. repo.untracked)
        end,
        hl = { fg = "git_change" },
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

        local source = shared.literal(venv_selector.source() or "")
        local python = shared.literal(venv_selector.python() or "")

        if python and python ~= "" then
            if source and source ~= "" then
                return " " .. source .. ":" .. python
            end
            return " " .. python
        end

        local venv_path = shared.literal(vim.env.VIRTUAL_ENV or "")
        if venv_path and venv_path ~= "" then
            return " " .. venv_path .. "/bin/python"
        end

        return " System"
    end,
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
            return "󰌛 " .. shared.literal(vim.fn.fnamemodify(solution, ":t:r"))
        end
        return ""
    end,
}

local LanguageEnv = {
    condition = function()
        return PythonEnv.condition() or CsharpEnv.condition()
    end,
    fallthrough = false,
    PythonEnv,
    CsharpEnv,
}

local MacroRec = {
    condition = function()
        return vim.fn.reg_recording() ~= "" and vim.o.cmdheight == 0
    end,
    update = {
        "RecordingEnter",
        "RecordingLeave",
        callback = vim.schedule_wrap(function()
            vim.cmd "redrawstatus"
        end),
    },
    provider = function()
        return " REC " .. vim.fn.reg_recording()
    end,
    hl = { fg = "orange" },
}

local DapMessages = {
    -- a require here would load nvim-dap on every redraw and defeat its lazy
    -- spec; no loaded module means no session
    condition = function()
        local dap = package.loaded.dap
        return dap ~= nil and dap.session() ~= nil
    end,
    provider = function()
        return " " .. require("dap").status()
    end,
    hl = "Debug",
}

local LspProgress = {
    condition = function()
        return activity.lsp() ~= nil
    end,
    init = function(self)
        self.text = activity.lsp()
    end,
    provider = function(self)
        return shared.literal(self.text)
    end,
    hl = { fg = "gray" },
}

-- one slot, and what you are doing outranks what a machine is doing for you
local Activity = {
    condition = function()
        return MacroRec.condition() or DapMessages.condition() or LspProgress.condition()
    end,
    fallthrough = false,
    MacroRec,
    DapMessages,
    LspProgress,
}

local FileEncoding = {
    provider = function()
        local enc = (vim.bo.fenc ~= "" and vim.bo.fenc) or vim.o.enc
        return enc:upper()
    end,
}

local function lsp_start(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end
    vim.notify("Starting LSP for " .. vim.bo[buf].filetype, vim.log.levels.INFO)
    vim.api.nvim_buf_call(buf, function()
        vim.cmd "doautocmd FileType"
    end)
end

local function lsp_clients_picker(clients)
    local items = {}
    for _, client in ipairs(clients) do
        items[#items + 1] = {
            text = client.name,
            name = client.name,
            root = client.root_dir,
        }
    end

    Snacks.picker.pick {
        title = "LSP Clients",
        items = items,
        layout = { preset = "select", layout = { max_width = 60 } },

        format = function(item)
            return {
                { item.text,       "SnacksPickerLabel" },
                { "  " },
                { item.root or "", "SnacksPickerComment" },
            }
        end,

        confirm = function(picker)
            picker:close()
        end,

        win = {
            input = {
                footer_keys = { "<c-r>", "<c-x>", "<c-l>" },
                keys = {
                    ["<c-r>"] = { "lsp_restart", desc = "Restart", mode = { "n", "i" } },
                    ["<c-x>"] = { "lsp_stop", desc = "Stop", mode = { "n", "i" } },
                    ["<c-l>"] = { "lsp_log", desc = "Log", mode = { "n", "i" } },
                },
            },
            list = {
                keys = {
                    ["r"] = "lsp_restart",
                    ["x"] = "lsp_stop",
                    ["l"] = "lsp_log",
                },
            },
        },

        actions = {
            lsp_restart = {
                desc = "Restart",
                action = function(picker)
                    local item = picker:current()
                    picker:close()
                    if item then
                        vim.cmd("lsp restart " .. item.name)
                    end
                end,
            },

            lsp_stop = {
                desc = "Stop",
                action = function(picker)
                    local item = picker:current()
                    picker:close()
                    if item then
                        vim.cmd("lsp stop " .. item.name)
                    end
                end,
            },

            lsp_log = {
                desc = "Log",
                action = function(picker)
                    picker:close()
                    vim.cmd("tabnew " .. vim.fn.fnameescape(vim.lsp.log.get_filename()))
                end,
            },
        },
    }
end

local LspActive = {
    update = { "LspAttach", "LspDetach" },

    on_click = {
        name = "heirline_lsp_clients",
        callback = function()
            local buf = vim.api.nvim_get_current_buf()
            local clients = vim.lsp.get_clients { bufnr = buf }
            if #clients > 0 then
                lsp_clients_picker(clients)
            else
                lsp_start(buf)
            end
        end,
    },

    provider = function()
        local names = {}
        for _, server in pairs(vim.lsp.get_clients { bufnr = 0 }) do
            table.insert(names, server.name)
        end
        if #names == 0 then
            return " No LSP"
        end
        return " " .. shared.literal(table.concat(names, ", "))
    end,

    hl = function()
        return #vim.lsp.get_clients { bufnr = 0 } == 0 and { fg = "gray" } or nil
    end,
}

local WorkDir = {
    init = function(self)
        self.cwd = vim.fn.fnamemodify(vim.fn.getcwd(0), ":~"):gsub("\\", "/")
    end,

    on_click = {
        name = "heirline_cwd",
        callback = function(_, _, _, button)
            if button == "r" then
                Snacks.picker.zoxide()
            else
                Snacks.picker.projects()
            end
        end,
    },

    {
        provider = function(self)
            return " " .. shared.literal(vim.fn.fnamemodify(self.cwd, ":t"))
        end,
    },

    hl = { fg = "git_add" },
}

local function selection()
    local kind = vim.fn.mode(true):sub(1, 1)
    if kind ~= "v" and kind ~= "V" and kind ~= "\22" then
        return nil
    end

    local lines = math.abs(vim.fn.line "v" - vim.fn.line ".") + 1
    local cols = math.abs(vim.fn.virtcol "v" - vim.fn.virtcol ".") + 1

    if kind == "\22" then
        return lines .. "x" .. cols .. " selected"
    elseif kind == "V" or lines > 1 then
        return lines .. " lines selected"
    end
    return cols .. " selected"
end


local Position = {
    init = function(self)
        self.selection = selection()
    end,
    provider = function(self)
        if self.selection then
            return "Ln %l, Col %c (" .. self.selection .. ")"
        end
        return "Ln %l, Col %c"
    end,
    hl = function(self)
        return self.selection and { fg = "purple", bold = true } or {}
    end,
}

local FileType = {
    provider = function()
        return vim.bo.filetype:upper()
    end,
}

local HelpFile = {
    condition = function()
        return vim.bo.filetype == "help"
    end,
    provider = function()
        return shared.literal(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"))
    end,
}

local TerminalName = {
    provider = function()
        return "  " .. shared.literal(vim.api.nvim_buf_get_name(0):gsub(".*:", ""))
    end,
}

local Special = shared.bar {
    condition = function()
        return conditions.buffer_matches {
            buftype = { "nofile", "prompt", "help", "quickfix" },
            filetype = { "^git.*", "fugitive" },
        }
    end,
    { FileType },
    { HelpFile },
    shared.Align,
}

local Terminal = shared.bar {
    condition = function()
        return conditions.buffer_matches { buftype = { "terminal" } }
    end,
    { ViMode,      bg = 1, cap_right = shared.cap.slope_right },
    { FileType },
    { TerminalName },
    shared.Align,
}

local Default = shared.bar {
    { ViMode,     bg = 1 },
    { WorkDir,    bg = 3, cap_right = shared.cap.arrow_right },
    { Git,        bg = 2, cap_right = shared.cap.arrow_right },
    { LanguageEnv },
    shared.Align,
    { Activity },
    shared.Align,
    { FileEncoding, },
    { Position },
    { provider = " " },
    { LspActive,     bg = 2 },
}

return {
    hl = function()
        return conditions.is_active() and shared.bg[3] or "StatusLineNC"
    end,

    fallthrough = false,

    Special,
    Terminal,
    Default,
}
