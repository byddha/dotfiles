return {
    "b0o/incline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local helpers = require "incline.helpers"
        local devicons = require "nvim-web-devicons"

        local function hex(group, attr)
            local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
            return hl[attr] and ("#%06x"):format(hl[attr]) or nil
        end

        -- Folded is what the statusline calls `bright_bg`, so the incline chip
        -- matches the statusline's segments instead of inventing its own color.
        local chip = {}
        local function setup_colors()
            chip.active = { bg = hex("Folded", "bg"), fg = hex("Normal", "fg") }
            chip.inactive = { bg = hex("NormalFloat", "bg"), fg = hex("Comment", "fg") }
        end
        setup_colors()

        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("InclineColors", { clear = true }),
            callback = setup_colors,
        })

        require("incline").setup {
            window = {
                padding = 0,
                margin = { horizontal = 0 },
            },
            render = function(props)
                local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
                if filename == "" then
                    filename = "[No Name]"
                end
                local ft_icon, ft_color = devicons.get_icon_color(filename)
                local modified = vim.bo[props.buf].modified
                local c = props.focused and chip.active or chip.inactive
                return {
                    ft_icon and { " ", ft_icon, " ", guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or "",
                    " ",
                    { filename, gui = modified and "bold,italic" or "bold", guifg = c.fg },
                    " ",
                    guibg = c.bg,
                }
            end,
        }
    end,
}
