return {
    "rachartier/tiny-code-action.nvim",
    dependencies = {
        { "nvim-lua/plenary.nvim" },
        { "folke/snacks.nvim" },
    },
    event = "LspAttach",
    opts = {
        backend = "delta",
        resolve_timeout = 1000,
        picker = "snacks",
    },
    keys = {
        {
            "ca",
            function()
                require("tiny-code-action").code_action()
            end,
            desc = "Code Action",
        },
    },
}
