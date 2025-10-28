local PYTHON_FILES = {
    ["pyproject.toml"] = true,
    ["setup.cfg"] = true,
    ["requirements.txt"] = true,
    ["Pipfile"] = true,
    ["tox.ini"] = true,
    ["uv.lock"] = true,
}

return {
    condition = function()
        if vim.bo.filetype == "python" then
            return true
        end
        local buf = vim.api.nvim_buf_get_name(0)

        local filename = vim.fn.fnamemodify(buf, ":t")
        if PYTHON_FILES[filename] then
            return true
        end

        return false
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
            return " " .. venv_path .. "/bin/python"
        end

        return " System"
    end,

    hl = { fg = "green", bold = true },
}
