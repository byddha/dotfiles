local M = { head = nil, insertions = 0, deletions = 0, untracked = 0 }

local DEBOUNCE = 150
local TIMEOUT = 10000

local timer = assert(vim.uv.new_timer())
local root, gitdir, watcher
local generation, busy, dirty, last_ms = 0, false, false, 0

local function first_line(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local line = file:read "l"
    file:close()
    return line
end

-- `.git` is a file in submodules and linked worktrees; its `gitdir:` payload is
-- relative to the directory holding that file, not to Neovim's cwd.
local function resolve_gitdir()
    local dot = vim.fs.joinpath(root, ".git")
    local stat = vim.uv.fs_stat(dot)
    if not stat then
        return nil
    end
    if stat.type == "directory" then
        return dot
    end

    local path = (first_line(dot) or ""):match "gitdir: (.-)%s*$"
    if path and not vim.startswith(path, "/") then
        path = vim.fs.normalize(vim.fs.joinpath(root, path))
    end
    return path
end

local function read_head()
    local line = gitdir and first_line(vim.fs.joinpath(gitdir, "HEAD"))
    if not line then
        return nil
    end
    return line:match "ref: refs/heads/(.+)" or line:sub(1, 7)
end

local function shortstat(out)
    return tonumber(out:match "(%d+) insertion") or 0, tonumber(out:match "(%d+) deletion") or 0
end

local refresh

local function collect()
    if busy or not root then
        return
    end
    busy, dirty = true, false

    local generation_at_start, started = generation, vim.uv.hrtime()
    local head = read_head()
    -- seeded from the last known values so a failed command carries its metric
    -- over instead of reporting a clean repo
    local insertions, deletions, untracked = M.insertions, M.deletions, M.untracked
    local pending = 2

    local function settle()
        pending = pending - 1
        if pending > 0 then
            return
        end

        busy = false
        last_ms = math.floor((vim.uv.hrtime() - started) / 1e6)

        local stale = generation_at_start ~= generation
        local changed = head ~= M.head
            or insertions ~= M.insertions
            or deletions ~= M.deletions
            or untracked ~= M.untracked

        if not stale and changed then
            M.head, M.insertions, M.deletions, M.untracked = head, insertions, deletions, untracked
            vim.schedule(function()
                vim.cmd "redrawstatus"
            end)
        end

        if dirty then
            refresh()
        end
    end

    -- vim.system throws from the call itself on a stale cwd, and the runtime
    -- does not catch a throwing callback; either would strand `pending`.
    local function run(cmd, handle)
        local opts = { cwd = root, text = true, timeout = TIMEOUT }
        local spawned = pcall(vim.system, cmd, opts, function(out)
            pcall(handle, out)
            settle()
        end)
        if not spawned then
            settle()
        end
    end

    -- plumbing, unlike `git diff`, so it never refreshes and rewrites the index
    run({ "git", "--no-optional-locks", "diff-index", "--shortstat", "HEAD" }, function(out)
        if out.code == 0 then
            insertions, deletions = shortstat(out.stdout)
        end
    end)

    local list = { "git", "--no-optional-locks", "ls-files", "--others", "--exclude-standard" }
    vim.list_extend(list, { "--directory", "--no-empty-directory", "-z" })
    run(list, function(out)
        if out.code ~= 0 then
            return
        end
        local count = 0
        for _ in vim.gsplit(out.stdout, "\0", { trimempty = true }) do
            count = count + 1
        end
        untracked = count
    end)
end

-- the delay tracks how long the last run took, so a repo where git needs
-- seconds is polled seconds apart instead of continuously
function refresh()
    dirty = true
    timer:stop()
    timer:start(math.max(DEBOUNCE, last_ms), 0, vim.schedule_wrap(collect))
end

local function close_watcher()
    if watcher and not watcher:is_closing() then
        watcher:close()
    end
    watcher = nil
end

local function attach()
    local found = vim.fs.root(0, ".git")
    if found == root then
        return
    end

    root = found
    generation = generation + 1
    M.head, M.insertions, M.deletions, M.untracked = nil, 0, 0, 0
    close_watcher()

    if not root then
        gitdir = nil
        return
    end

    gitdir = resolve_gitdir()
    if gitdir then
        watcher = assert(vim.uv.new_fs_event())
        -- uv returns the error rather than throwing, and a handle whose start
        -- failed still has to be closed
        if not watcher:start(gitdir, {}, vim.schedule_wrap(refresh)) then
            close_watcher()
        end
    end
    refresh()
end

local group = vim.api.nvim_create_augroup("HeirlineGit", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, { group = group, callback = refresh })
vim.api.nvim_create_autocmd({ "DirChanged", "BufEnter" }, { group = group, callback = attach })

attach()

return M
