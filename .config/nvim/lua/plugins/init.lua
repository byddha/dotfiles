return {
    {
        -- "dms" is colors/dms.lua, written by theme-set from the DMS palette:
        -- base46's kanagawa tinted towards the current desktop accent.
        -- Not a base46-* name, so it cannot be lazy loaded on colorscheme.
        "AvengeMedia/base46",
        lazy = false,
        priority = 1500,
        opts = {},
        config = function(_, opts)
            require("base46").setup(opts)

            -- kanagawa hardcoded these; derive them so they follow the theme
            vim.api.nvim_create_autocmd("ColorScheme", {
                callback = function()
                    local function hl(name)
                        return vim.api.nvim_get_hl(0, { name = name, link = false })
                    end
                    -- not every theme gives LineNr a background
                    vim.api.nvim_set_hl(0, "DapStopped", {
                        bg = hl("LineNr").bg or hl("CursorLine").bg or hl("NormalFloat").bg,
                    })
                    vim.api.nvim_set_hl(0, "SnacksPickerTree", {
                        bg = hl("NormalFloat").bg,
                        fg = hl("Comment").fg,
                    })
                end,
            })

            -- colors/dms.lua is written by theme-set, so it only exists on the
            -- linux box; elsewhere fall back to the base46 theme it is built on
            if not pcall(vim.cmd.colorscheme, "dms") then
                vim.cmd.colorscheme "base46-kanagawa"
            end
        end,
    },
    { import = "plugins.ai" },
    { import = "plugins.coding" },
    { import = "plugins.debugging" },
    { import = "plugins.editor" },
    { import = "plugins.lsp" },
    { import = "plugins.ui" },
    { import = "plugins.utils" },
    { import = "plugins.snacks" },
}
