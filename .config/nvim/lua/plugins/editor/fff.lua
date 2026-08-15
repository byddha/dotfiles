return {
    "dmtrKovalenko/fff.nvim",
    build = function()
        require("fff.download").download_or_build_binary()
    end,
    lazy = false,
    opts = {
        layout = {
            prompt_position = "bottom",
            preview_position = "right",
        },
        git = {
            status_text_color = true,
        },
        keymaps = {
            move_up = { "<Up>", "<C-p>", "<C-k>" },
            move_down = { "<Down>", "<C-n>", "<C-j>" },
        },
    },
    -- fff builds its own floats (zindex 51+) and has no backdrop option, so
    -- reproduce the one Snacks.win draws for lazygit and the pickers.
    config = function(_, opts)
        require("fff").setup(opts)
        vim.api.nvim_set_hl(0, "FffBackdrop", { bg = "#000000", default = true })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "fff_input",
            callback = function(args)
                local win = vim.fn.win_findbuf(args.buf)[1]
                if not win then
                    return
                end

                local backdrop = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, {
                    relative = "editor",
                    row = 0,
                    col = 0,
                    width = vim.o.columns,
                    height = vim.o.lines,
                    style = "minimal",
                    border = "none", -- else it inherits the global 'winborder'
                    focusable = false,
                    zindex = 50, -- fff's own floats start at 51
                })
                vim.wo[backdrop].winhighlight = "Normal:FffBackdrop,NormalFloat:FffBackdrop"
                vim.wo[backdrop].winblend = 40 -- lower = darker

                vim.api.nvim_create_autocmd("WinClosed", {
                    pattern = tostring(win),
                    once = true,
                    callback = function()
                        pcall(vim.api.nvim_win_close, backdrop, true)
                    end,
                })
            end,
        })
    end,
    keys = {
        {
            "<leader>ff",
            function()
                require("fff").find_files()
            end,
            desc = "Find Files",
        },
        {
            "<leader>fw",
            function()
                require("fff").live_grep()
            end,
            desc = "Grep",
        },
    },
}
