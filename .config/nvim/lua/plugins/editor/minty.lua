return {
    "nvzone/minty",
    dependencies = {
        "nvzone/volt"
    },
    cmd = { "Huefy", "Shades" },
    keys = {
        {
            "<C-c>",
            function()
                if vim.bo.buftype ~= "terminal" then
                    require("minty.huefy").open()
                end
            end,
            mode = "i",
            desc = "Open color picker",
        },
    },
}
