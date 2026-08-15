return {
    "rebelot/heirline.nvim",
    event = "UIEnter",
    -- registered during startup so it is in place before command-line files are read
    init = function()
        require "plugins.ui.heirline.activity"
    end,
    config = function()
        local conditions = require "heirline.conditions"
        local utils = require "heirline.utils"

        local function setup_colors()
            return {
                bright_bg = utils.get_highlight("Folded").bg,
                bright_fg = utils.get_highlight("Folded").fg,
                green = utils.get_highlight("String").fg,
                blue = utils.get_highlight("Function").fg,
                gray = utils.get_highlight("NonText").fg,
                orange = utils.get_highlight("Constant").fg,
                purple = utils.get_highlight("Statement").fg,
                cyan = utils.get_highlight("Special").fg,
                diag_warn = utils.get_highlight("DiagnosticWarn").fg,
                diag_error = utils.get_highlight("DiagnosticError").fg,
                diag_hint = utils.get_highlight("DiagnosticHint").fg,
                diag_info = utils.get_highlight("DiagnosticInfo").fg,
                git_del = utils.get_highlight("diffDeleted").fg,
                git_add = utils.get_highlight("diffAdded").fg,
                git_change = utils.get_highlight("diffChanged").fg,
            }
        end

        -- The bar's two accent zones. Kept as named groups rather than palette
        -- entries so anything else can link to them.
        local function setup_zones()
            local folded = utils.get_highlight "Folded"
            local base = utils.get_highlight "StatusLine"
            vim.api.nvim_set_hl(0, "StatusLineBg1", { fg = folded.bg, bg = utils.get_highlight("Statement").fg })
            vim.api.nvim_set_hl(0, "StatusLineBg2", { fg = folded.fg, bg = folded.bg })
            vim.api.nvim_set_hl(0, "StatusLineBg3", { fg = base.fg, bg = base.bg })
        end
        setup_zones()

        require("heirline").setup {
            statusline = require "plugins.ui.heirline.statusline",
            opts = {
                colors = setup_colors(),
                disable_winbar_cb = function(args)
                    return conditions.buffer_matches({
                        buftype = { "nofile", "prompt", "help", "quickfix" },
                        filetype = { "^git.*", "fugitive", "Trouble", "dashboard" },
                    }, args.buf)
                end,
            },
        }

        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("Heirline", { clear = true }),
            callback = function()
                setup_zones()
                utils.on_colorscheme(setup_colors)
            end,
        })
    end,
}
