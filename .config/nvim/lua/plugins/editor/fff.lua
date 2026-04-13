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
