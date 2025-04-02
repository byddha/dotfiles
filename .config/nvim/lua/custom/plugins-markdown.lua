local function fetch_about_from_github(url)
    local repo_path = url:match "github.com/(.+)$"
    if not repo_path then
        return "No description available", "Unknown Author"
    end

    repo_path = repo_path:gsub("%.git$", "")

    local about = "N/A"
    local author = "N/A"
    local stdout = vim.loop.new_pipe(false)
    local stderr = vim.loop.new_pipe(false)

    if not stdout or not stderr then
        return about, author
    end

    local handle
    ---@diagnostic disable-next-line: missing-fields
    handle = vim.loop.spawn("gh", {
        args = {
            "repo",
            "view",
            repo_path,
            "--json",
            "description,owner",
            "--jq",
            "{description: .description, author: .owner.login}",
        },
        stdio = { nil, stdout, stderr },
    }, function(code, _)
        stdout:close()
        stderr:close()
        if code ~= 0 then
            print("gh failed with code: " .. code)
        end
        handle:close()
    end)

    local output = ""
    stdout:read_start(function(err, data)
        assert(not err, err)
        if data then
            output = output .. data
        end
    end)

    stderr:read_start(function(err, data)
        assert(not err, err)
        if data then
            print("Error: " .. data) -- Debugging
        end
    end)

    vim.wait(5000, function()
        return not vim.loop.is_active(handle)
    end, 100)

    if #output > 0 then
        local json = vim.fn.json_decode(output)
        about = json.description or about
        author = json.author or author
    end

    return about, author
end

local function fetch_mason_installed_packages()
    local mason_registry = require "mason-registry"
    local packages = mason_registry.get_installed_packages()
    local package_details = {}

    for _, package in ipairs(packages) do
        local pkg_name = package.name or "Unknown Package"
        local homepage = package.spec.homepage or "URL not available"

        homepage = homepage:gsub("/$", "")

        if not homepage:match "github.com/.+/.+" then
            table.insert(package_details, {
                name = pkg_name,
                homepage = homepage,
                description = "N/A",
                author = "N/A",
                stars = 0,
            })
        else
            local description, author, stars = fetch_about_from_github(homepage)
            table.insert(package_details, {
                name = pkg_name,
                homepage = homepage,
                description = description,
                author = author,
                stars = stars,
            })
        end
    end

    return package_details
end

local function open_in_new_buffer(content)
    local lines = {}
    for _, line in ipairs(content) do
        for split_line in line:gmatch "[^\r\n]+" do
            table.insert(lines, split_line)
        end
    end

    vim.cmd "vsplit"
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)

    vim.bo[buf].modifiable = true
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "markdown"

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
end
local function generate_markdown_for_plugins()
    local lazy = require "lazy"

    if not lazy then
        vim.notify("Lazy.nvim not found!", vim.log.levels.ERROR)
        return
    end

    local plugins = lazy.plugins()
    if not plugins then
        vim.notify("No plugins found!", vim.log.levels.ERROR)
        return
    end

    local mason_plugin = nil
    local other_plugins = {}

    for _, plugin in ipairs(plugins) do
        if plugin.name == "mason.nvim" then
            mason_plugin = plugin
        else
            table.insert(other_plugins, plugin)
        end
    end

    table.sort(other_plugins, function(a, b)
        return (a.name or ""):lower() < (b.name or ""):lower()
    end)

    local markdown_lines = { "# Packages\n" }

    if mason_plugin then
        local url = mason_plugin.url or "URL not available"
        local description, author = fetch_about_from_github(url)
        local repo_path = url:match("github.com/(.+)$"):gsub("%.git$", "")
        local stars_badge = string.format("![Stars](https://img.shields.io/github/stars/%s?style=flat)", repo_path)

        table.insert(markdown_lines, string.format("## 📌 [%s](%s) %s", mason_plugin.name, url, stars_badge))
        table.insert(markdown_lines, string.format("- **Author**: %s", author))
        table.insert(markdown_lines, string.format("- **About**: %s", description))

        local mason_packages = fetch_mason_installed_packages()
        if #mason_packages > 0 then
            table.sort(mason_packages, function(a, b)
                return (a.name or ""):lower() < (b.name or ""):lower()
            end)
            for _, pkg in ipairs(mason_packages) do
                local stars_badge = pkg.homepage:match "github.com/.+/.+"
                        and string.format(
                            "![Stars](https://img.shields.io/github/stars/%s?style=flat)",
                            pkg.homepage:match "github.com/(.+)$"
                        )
                    or ""
                table.insert(markdown_lines, string.format("  - **[%s](%s)** %s", pkg.name, pkg.homepage, stars_badge))
                if pkg.author ~= "N/A" then
                    table.insert(markdown_lines, string.format("    - **Author**: %s", pkg.author))
                end
                if pkg.description ~= "N/A" then
                    table.insert(markdown_lines, string.format("    - **About**: %s", pkg.description))
                end
                table.insert(markdown_lines, "")
            end
        end
    end

    for _, plugin in ipairs(other_plugins) do
        local name = plugin.name or "Unknown Plugin"
        local url = plugin.url or "URL not available"
        local description, author = fetch_about_from_github(url)

        local repo_path = nil
        if url:find "github.com/" then
            repo_path = url:match "github.com/(.+)$"
            if repo_path then
                repo_path = repo_path:gsub("%.git$", "")
            end
        end

        local stars_badge = ""
        if repo_path then
            stars_badge = string.format("![Stars](https://img.shields.io/github/stars/%s?style=flat)", repo_path)
        end

        table.insert(markdown_lines, string.format("## [%s](%s) %s", name, url, stars_badge))
        table.insert(markdown_lines, string.format("- **Author**: %s", author))
        table.insert(markdown_lines, string.format("- **About**: %s", description))
        table.insert(markdown_lines, "")
    end

    open_in_new_buffer(markdown_lines)
end

vim.api.nvim_create_user_command("PluginsMarkdown", function()
    generate_markdown_for_plugins()
end, { desc = "Generate Markdown for Installed Plugins and Mason Packages" })
