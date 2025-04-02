return {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    opts = function()
        return {
            auto_install = true,
            ensure_installed = { "lua", "luadoc", "printf", "vim", "vimdoc" },
            highlight = {
                enable = true,
                use_languagetree = true,
            },

            indent = { enable = true },
        }
    end,
    config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)
    end,
}
