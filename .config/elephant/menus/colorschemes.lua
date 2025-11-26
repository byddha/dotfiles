Name = "colorschemes"
NamePretty = "Color Schemes"
Cache = false
Action = "theme-set %VALUE%"
HideFromProviderlist = false
Description = "Base16 Color Schemes"
SearchName = true

local function formatName(name)
	return name:gsub("-", " "):gsub("(%a)([%w]*)", function(first, rest)
		return first:upper() .. rest
	end)
end

function GetEntries()
	local entries = {}
	local base16_dir = "/home/bida/.config/base16"
	local handle = io.popen('ls "' .. base16_dir .. '"/*.yaml 2>/dev/null')
	if handle then
		for file in handle:lines() do
			local name = file:match("([^/]+)%.yaml$")
			if name then
				table.insert(entries, {
					Text = formatName(name),
					Value = name,
					Icon = base16_dir .. "/" .. name .. ".png",
				})
			end
		end
		handle:close()
	end
	return entries
end
