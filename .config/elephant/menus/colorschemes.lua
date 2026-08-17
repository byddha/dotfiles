Name = "colorschemes"
NamePretty = "Color Schemes"
Cache = true
Action = "bash ~/dotfiles/scripts/theme-set %VALUE%"
HideFromProviderlist = false
Description = "Desktop Color Schemes"
SearchName = true

-- Themes come from the DMS registry that theme-set bootstraps, plus anything
-- dropped in the local overrides dir. Each theme ships its own preview svg.
local theme_dirs = {
	os.getenv("HOME") .. "/.local/share/theme-set/registry/themes",
	os.getenv("HOME") .. "/dotfiles/.config/dms-themes",
}

local function formatName(name)
	return name:gsub("-", " "):gsub("(%a)([%w]*)", function(first, rest)
		return first:upper() .. rest
	end)
end

local function fileExists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

function GetEntries()
	local entries = {}
	local seen = {}

	for _, dir in ipairs(theme_dirs) do
		local handle = io.popen('ls "' .. dir .. '" 2>/dev/null')
		if handle then
			for name in handle:lines() do
				if not seen[name] and fileExists(dir .. "/" .. name .. "/theme.json") then
					seen[name] = true
					local icon = dir .. "/" .. name .. "/preview-dark.svg"
					if not fileExists(icon) then
						icon = dir .. "/" .. name .. "/preview.svg"
					end
					table.insert(entries, {
						Text = formatName(name),
						Value = name,
						Icon = icon,
					})
				end
			end
			handle:close()
		end
	end

	return entries
end
