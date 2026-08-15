return {
    "williamboman/mason.nvim",
    -- must load before nvim-lspconfig so mason's bin dir is on PATH when servers spawn
    lazy = false,
    priority = 100,
    opts = function()
        return {
            ui = {
                icons = {
                    package_pending = " ",
                    package_installed = " ",
                    package_uninstalled = " ",
                },
            },

            max_concurrent_installers = 10,

            registries = {
                "github:mason-org/mason-registry",
                "github:Crashdummyy/mason-registry",
            }
        }
    end,
}
