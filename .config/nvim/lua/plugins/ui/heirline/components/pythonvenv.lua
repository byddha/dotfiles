return {
    condition = function()
        return vim.bo.filetype == "python"
    end,

    provider = function()
        local ok, venv_selector = pcall(require, "venv-selector")
        if not ok then
            return ""
        end

        local source = venv_selector.source()
        local python = venv_selector.python()

        if python and python ~= "" then
            if source and source ~= "" then
                return " " .. source .. ":" .. python
            else
                return " " .. python
            end
        end

        local venv_path = vim.env.VIRTUAL_ENV
        if venv_path and venv_path ~= "" then
            return " " .. venv_path .. "/bin/python3"
        end

        return " System"
    end,

    hl = { fg = "blue", bold = true },
}
