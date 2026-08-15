local angularls_path = vim.fn.stdpath "data" .. "/mason/packages/angular-language-server"

return {
    cmd = {
        "ngserver",
        "--stdio",
        "--tsProbeLocations",
        table.concat({
            angularls_path,
            vim.uv.cwd(),
        }, ","),
        "--ngProbeLocations",
        table.concat({
            angularls_path .. "/node_modules/@angular/language-server",
            vim.uv.cwd(),
        }, ","),
    },
}
