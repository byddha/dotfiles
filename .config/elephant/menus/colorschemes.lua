Name = "colorschemes"
NamePretty = "Color Schemes"
Cache = true
Action = "bash ~/dotfiles/scripts/theme-set %VALUE%"
HideFromProviderlist = false
Description = "Desktop Color Schemes"
SearchName = true

-- theme-set --menu prints one 'args<TAB>label<TAB>icon' row per selectable
-- combination, previews included. Values carry their own flags, so
-- "catppuccin --flavor mocha --accent blue" runs as-is through Action.
local menu_cmd = os.getenv("HOME") .. "/dotfiles/scripts/theme-set --menu 2>/dev/null"

function GetEntries()
	local entries = {}

	local handle = io.popen(menu_cmd)
	if not handle then
		return entries
	end

	for line in handle:lines() do
		local value, text, icon = line:match("^([^\t]*)\t([^\t]*)\t(.*)$")
		if value and value ~= "" then
			table.insert(entries, {
				Text = text,
				Value = value,
				Icon = icon,
			})
		end
	end
	handle:close()

	return entries
end
