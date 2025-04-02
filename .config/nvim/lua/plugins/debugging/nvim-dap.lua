return {
    "mfussenegger/nvim-dap",
    keys = {
        {
            "<F5>",
            function()
                require("overseer").enable_dap()
                if vim.fn.filereadable ".vscode/launch.json" then
                    require("dap.ext.vscode").load_launchjs()
                end
                require("dap").continue()
            end,
            desc = "Start / Continue execution",
        },
        {
            "<F10>",
            function()
                require("dap").step_over()
            end,
            desc = "Step over",
        },
        {
            "<F11>",
            function()
                require("dap").step_into()
            end,
            desc = "Step into",
        },
        {
            "<leader>db",
            function()
                require("dap").toggle_breakpoint()
            end,
            desc = "Toggle breakpoint",
        },
        {
            "<leader>dB",
            function()
                require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
            end,
            desc = "Set conditional breakpoint",
        },
        {
            "leader>dl",
            function()
                require("dap").run_last()
            end,
            desc = "Run last debug session",
        },
    },
    config = function()
        vim.fn.sign_define("DapBreakpoint", { text = "🤡", texthl = "", linehl = "", numhl = "" })
        vim.fn.sign_define("DapBreakpointCondition", { text = "💀", texthl = "", linehl = "", numhl = "" })
        vim.fn.sign_define("DapBreakpointRejected", { text = "😵", texthl = "", linehl = "", numhl = "" })
        vim.fn.sign_define(
            "DapStopped",
            { text = "", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" }
        )

        require("nvim-dap-virtual-text").setup()

        require "plugins.debugging.configs.godot"
        require "plugins.debugging.configs.debugpy"
        require "plugins.debugging.configs.typescript"
        require "plugins.debugging.configs.codelldb"

        local ok, _ = pcall(require, "plugins.debugging.dotnet.dotnet")
        if not ok then
            vim.notify("dap-dotnet not installed", vim.log.levels.WARN)
        end
    end,
}
