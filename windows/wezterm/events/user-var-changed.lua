---@diagnostic disable: undefined-field
local wt = require "wezterm"
local M = {}

-- Table to store program state per tab
local pane_programs = {}

-- Store program state when user var changes
wt.on("user-var-changed", function(_, pane, name, value)
  if name == "PROG" then
    local id = pane:pane_id()
    pane_programs[id] = value ~= "" and value or nil
  end
end)

-- Get program state for a pane
function M.get_process_osc1337(pane)
  if not pane then
    return nil
  end
  return pane_programs[pane.pane_id]
end

return M
