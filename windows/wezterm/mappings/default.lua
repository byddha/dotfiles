---@module "mappings.default"
---@author sravioli
---@license GNU-GPLv3

---@diagnostic disable-next-line: undefined-field
local act = require("wezterm").action
local key = require("utils.fn").key

local Config = {}

Config.disable_default_key_bindings = true
Config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 3000 }

local mappings = {
  { "<C-Tab>", act.ActivateTabRelative(1), "next tab" },
  { "<C-S-Tab>", act.ActivateTabRelative(-1), "prev tab" },
  { "<M-CR>", act.ToggleFullScreen, "fullscreen" },
  { "<C-S-c>", act.CopyTo "Clipboard", "copy" },
  { "<C-S-v>", act.PasteFrom "Clipboard", "paste" },
  { "<C-S-f>", act.Search "CurrentSelectionOrEmptyString", "search" },
  { "<C-S-k>", act.ClearScrollback "ScrollbackOnly", "clear scrollback" },
  { "<C-S-l>", act.ShowDebugOverlay, "debug overlay" },
  { "<C-S-n>", act.SpawnWindow, "new window" },
  { "<C-S-p>", act.ActivateCommandPalette, "command palette" },
  { "<C-S-r>", act.ReloadConfiguration, "reload config" },
  { "<C-t>", act.SpawnTab "CurrentPaneDomain", "new pane" },
  {
    "<C-S-u>",
    act.CharSelect {
      copy_on_select = true,
      copy_to = "ClipboardAndPrimarySelection",
    },
    "char select",
  },
  { "<M-q>", act.CloseCurrentTab { confirm = true }, "close tab" },
  { "<M-z>", act.TogglePaneZoomState, "toggle zoom" },
  { "<PageUp>", act.ScrollByPage(-1), "" },
  { "<PageDown>", act.ScrollByPage(1), "" },
  { "<C-S-Insert>", act.PasteFrom "PrimarySelection", "" },
  { "<C-Insert>", act.CopyTo "PrimarySelection", "" },
  { "<C-S-Space>", act.QuickSelect, "quick select" },
  {
    "<S-M-t>",
    act.ShowLauncherArgs {
      title = "  Search:",
      flags = "FUZZY|LAUNCH_MENU_ITEMS|DOMAINS",
    },
    "new window",
  },

  ---quick split and nav
  { "<M-v>", act.SplitHorizontal { domain = "CurrentPaneDomain" }, "vsplit" },
  { "<M-s>", act.SplitVertical { domain = "CurrentPaneDomain" }, "hsplit" },
  { "<M-h>", act.ActivatePaneDirection "Left", "move left" },
  { "<M-j>", act.ActivatePaneDirection "Down", "mode down" },
  { "<M-k>", act.ActivatePaneDirection "Up", "move up" },
  { "<M-l>", act.ActivatePaneDirection "Right", "move right" },

  ---key tables
  { "<M-S-?>", act.ActivateKeyTable { name = "help_mode", one_shot = true }, "help" },
  {
    "<M-w>",
    act.ActivateKeyTable { name = "window_mode", one_shot = false },
    "window mode",
  },
  { "<M-c>", act.ActivateCopyMode, "copy mode" },
  { "<M-f>", act.Search "CurrentSelectionOrEmptyString", "search mode" },
  { "<M-p>", act.ActivateKeyTable { name = "pick_mode" }, "pick mode" },
}

for i = 1, 9 do
  mappings[#mappings + 1] =
    { "<M-" .. i .. ">", act.ActivateTab(i - 1), "activate tab " .. i }
end

Config.keys = {}
for _, map_tbl in ipairs(mappings) do
  key.map(map_tbl[1], map_tbl[2], Config.keys)
end

return Config
