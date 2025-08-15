---@diagnostic disable: undefined-field

local wt = require "wezterm"

local Config = {}

Config.adjust_window_size_when_changing_font_size = false
Config.allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace"
Config.anti_alias_custom_block_glyphs = true

Config.font = wt.font { family = "CaskaydiaCove Nerd Font" }
Config.font_size = 14.0

return Config
