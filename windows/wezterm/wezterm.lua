local Config = require("utils.class.config"):new()

require "events.update-status"
require "events.format-tab-title"
require "events.new-tab-button-click"
require "events.augment-command-palette"
require "events.user-var-changed"

return Config:add("config"):add "mappings"
