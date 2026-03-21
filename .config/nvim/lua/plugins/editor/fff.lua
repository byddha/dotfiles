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
