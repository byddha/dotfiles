-- Currently using fzf-lua only for LSP code actions. Check in the future if Snacks can replace it.
return {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    opts = function(_, _)
        return {
            "default-title",
            fzf_colors = true,
            fzf_opts = {
                ["--no-scrollbar"] = true,
            },
            defaults = {
                -- formatter = "path.filename_first",
                formatter = "path.dirname_first",
            },
            winopts = {
                width = 0.8,
                height = 0.8,
                row = 0.5,
                col = 0.5,
                preview = {
                    scrollchars = { "┃", "" },
                },
            },
            lsp = {
                symbols = {
                    symbol_hl = function(s)
                        return "TroubleIcon" .. s
                    end,
                    symbol_fmt = function(s)
                        return s:lower() .. "\t"
                    end,
                    child_prefix = false,
                },
                code_actions = {
                    previewer = vim.fn.executable "delta" == 1 and "codeaction_native" or nil,
                },
            },
        }
    end,
    config = function(_, opts)
        if opts[1] == "default-title" then
            -- use the same prompt for all pickers for profile `default-title` and
            -- profiles that use `default-title` as base profile
            local function fix(t)
                t.prompt = t.prompt ~= nil and " " or nil
                for _, v in pairs(t) do
                    if type(v) == "table" then
                        fix(v)
                    end
                end
                return t
            end
            opts = vim.tbl_deep_extend("force", fix(require "fzf-lua.profiles.default-title"), opts)
            opts[1] = nil
        end
        require("fzf-lua").setup(opts)
    end,
    keys = {
        {
            "ca",
            "<cmd>FzfLua lsp_code_actions<cr>",
            desc = "Code Actions",
        },
    },
}
