local mp = require 'mp'
local msg = require 'mp.msg'
local options = require 'mp.options'

if mp.get_property("platform") ~= "linux" then return end

local opts = {
    tag = "watched",
    min_seconds = 120,
}
options.read_options(opts, "tagwatched")

local last_pos = 0
local current_file = nil

local function abs_path(path)
    if not path or path:find("://") then return nil end
    if path:sub(1, 1) == "/" then return path end
    local wd = mp.get_property("working-directory")
    return wd and (wd .. "/" .. path) or nil
end

local function run(args)
    return mp.command_native({
        name = "subprocess",
        args = args,
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
    })
end

local function get_tags(file)
    local r = run({"getfattr", "--only-values", "-n", "user.xdg.tags", "--", file})
    local tags = {}
    if r.status ~= 0 then return tags end
    for t in (r.stdout or ""):gmatch("[^,]+") do
        t = t:match("^%s*(.-)%s*$")
        if t ~= "" then tags[#tags + 1] = t end
    end
    return tags
end

local function add_tag(file)
    local tags = get_tags(file)
    for _, t in ipairs(tags) do
        if t == opts.tag then return end
    end
    tags[#tags + 1] = opts.tag
    local r = run({"setfattr", "-n", "user.xdg.tags",
                   "-v", table.concat(tags, ","), "--", file})
    if r.status ~= 0 then
        msg.warn("setfattr failed: " .. (r.stderr or ""))
    else
        msg.info("tagged: " .. file)
    end
end

local function maybe_tag()
    local file = current_file
    current_file = nil
    if file and last_pos >= opts.min_seconds then
        add_tag(file)
    end
end

mp.observe_property("time-pos", "number", function(_, v)
    if v then last_pos = v end
end)

mp.register_event("file-loaded", function()
    last_pos = 0
    current_file = abs_path(mp.get_property("path"))
end)

mp.register_event("end-file", maybe_tag)
mp.register_event("shutdown", maybe_tag)
