return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    opts = {
        ensure_installed = {
            -- core / nvim
            "lua",
            "luadoc",
            "vim",
            "vimdoc",
            "query",
            "regex",
            "printf",

            -- shell
            "bash",

            -- web
            "html",
            "css",
            "javascript",
            "typescript",
            "tsx",
            "json",
            "yaml",
            "toml",

            -- python
            "python",

            -- c family
            "c",
            "cpp",

            -- c#
            "c_sharp",

            -- markup / docs
            "markdown",
            "markdown_inline",

            -- embedded / hardware
            "devicetree",

            -- config / ops
            "diff",
            "gitcommit",
            "gitignore",
            "dockerfile",
            "hyprlang",
        },
    },
    config = function(_, opts)
        local TS = require "nvim-treesitter"
        TS.setup(opts)

        local installed = require("nvim-treesitter.config").get_installed() or {}
        local missing = vim.tbl_filter(function(lang)
            return not vim.tbl_contains(installed, lang)
        end, opts.ensure_installed)
        if #missing > 0 then
            TS.install(missing)
        end

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
            callback = function(ev)
                pcall(vim.treesitter.start, ev.buf)
                vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })
    end,
}
