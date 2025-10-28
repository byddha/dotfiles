local CSHARP_FILES = {
    ["*.csproj"] = true,
    ["*.sln"] = true,
}

return {
    condition = function()
        if vim.bo.filetype == "cs" then
            return true
        end
        local buf = vim.api.nvim_buf_get_name(0)

        local filename = vim.fn.fnamemodify(buf, ":t")
        if CSHARP_FILES[filename] or filename:match "%.csproj$" or filename:match "%.sln$" then
            return true
        end

        return false
    end,

    provider = function()
        local selected_solution = vim.g.roslyn_nvim_selected_solution

        if selected_solution and selected_solution ~= "" then
            local solution_name = vim.fn.fnamemodify(selected_solution, ":t:r")
            return "󰌛 " .. solution_name
        end

        return ""
    end,

    hl = { fg = "purple", bold = true },
}
