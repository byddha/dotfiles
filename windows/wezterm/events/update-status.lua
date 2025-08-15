---@diagnostic disable: undefined-field
---@module "events.update-status"

local class = require "utils.class"
local fn = require "utils.fn"
local wt = require "wezterm"

local icon = class.icon
local sep = class.icon.Sep
local StatusBar = class.layout:new "StatusBar"
local fs, mt, str, tbl = fn.fs, fn.mt, fn.str, fn.tbl

local sys_cache = { data = nil, last_update = 0 }
local media_cache = { data = nil, last_update = 0 }

local function get_modes(theme)
  return {
    search_mode = { i = "󰍉", txt = "SEARCH", bg = theme.brights[4], pad = 5 },
    window_mode = { i = "󱂬", txt = "WINDOW", bg = theme.ansi[6], pad = 4 },
    copy_mode = { i = "󰆏", txt = "COPY", bg = theme.brights[3], pad = 5 },
    font_mode = { i = "󰛖", txt = "FONT", bg = theme.ansi[7], pad = 4 },
    help_mode = { i = "󰞋", txt = "NORMAL", bg = theme.ansi[5], pad = 5 },
    pick_mode = { i = "󰢷", txt = "PICK", bg = theme.ansi[2], pad = 5 },
  }
end

local function create_modal_indicator(window, modes, lsb, bg, width)
  local mode = window:active_key_table()
  if mode and modes[mode] then
    local mode_fg = modes[mode].bg
    local txt, ico = modes[mode].txt or "", modes[mode].i or ""
    local indicator = str.pad(str.padr(ico) .. txt, 1)
    lsb:append(mode_fg, bg, indicator, { "Bold" })
    width.mode = str.width(indicator)
  end
  return width
end

local function create_workspace_indicator(window, lsb, theme, bg, mode, width)
  local ws = window:active_workspace()
  if ws ~= "" and not mode then
    local ws_bg = theme.brights[6]
    ws = str.pad(str.padr(icon.Workspace) .. ws)
    width.ws = str.width(ws) + 4

    if width.usable >= width.ws then
      lsb:append(ws_bg, bg, ws, { "Bold" })
    end
  end
  return width
end

local function get_platform_commands()
  if wt.target_triple:find "windows" then
    return {
      "powershell",
      "-Command",
      [[(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory,(Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize]],
    }, {
      "typeperf",
      "\\Processor Information(_Total)\\% Processor Utility",
      "-sc",
      "1",
    }
  elseif wt.target_triple:find "darwin" then
    return { "sysctl", "-n", "hw.memsize" }, { "top", "-l", "1", "-n", "0" }
  else
    return { "free", "-b" }, { "top", "-bn1" }
  end
end

local function process_memory_stats(output)
  local used, total = 0, 0

  if wt.target_triple:find "windows" then
    local free, total_kb = output:match "(%d+)%s+(%d+)"
    if free and total_kb then
      total = tonumber(total_kb) * 1024
      used = total - (tonumber(free) * 1024)
    end
  elseif wt.target_triple:find "darwin" then
    total = tonumber(output)
    local vm_success, vm_out = wt.run_child_process { "vm_stat" }
    if vm_success then
      local pages_active = tonumber(vm_out:match "Pages active:%s+(%d+)") or 0
      local pages_wired = tonumber(vm_out:match "Pages wired down:%s+(%d+)") or 0
      used = (pages_active + pages_wired) * 4096
    end
  else
    local mem = output:match "Mem:%s+(%d+)%s+(%d+)"
    total = tonumber(mem)
    used = tonumber(select(2, mem))
  end

  if total > 0 then
    return {
      used = string.format("%.1f", used / 1024 / 1024 / 1024),
      total = string.format("%.1f", total / 1024 / 1024 / 1024),
    }
  end
  return { used = "N/A", total = "N/A" }
end

local function process_cpu_stats(output)
  if wt.target_triple:find "windows" then
    local cpu_value = output:match '"[^"]+","([%d%.]+)"'
    local cpu = math.floor(tonumber(cpu_value) or 0)
    return math.max(0, math.min(100, cpu < 1.5 and 0 or cpu))
  elseif wt.target_triple:find "darwin" then
    local cpu = output:match "CPU usage:%s+([%d%.]+)%%"
    return tonumber(cpu) or 0
  else
    local cpu = output:match "%%Cpu%(s%):%s+([%d%.]+)"
    return tonumber(cpu) or 0
  end
end

local function get_system_stats()
  local now = os.time()
  if sys_cache.data and now - sys_cache.last_update < 5 then
    return sys_cache.data
  end

  local stats = { memory = {}, cpu = 0 }
  local mem_cmd, cpu_cmd = get_platform_commands()

  local mem_success, mem_output = wt.run_child_process(mem_cmd)
  if mem_success then
    stats.memory = process_memory_stats(mem_output)
  end

  local cpu_success, cpu_output = wt.run_child_process(cpu_cmd)
  if cpu_success then
    stats.cpu = process_cpu_stats(cpu_output)
  end

  sys_cache.data = stats
  sys_cache.last_update = now
  return stats
end

local function get_media_info()
  local now = os.time()
  if now - media_cache.last_update < 5 then
    return media_cache.data
  end

  local success, output = wt.run_child_process { "mtlq", "now", "--distinct" }
  if not success then
    return nil
  end

  local data = wt.json_parse(output)
  if not data or #data == 0 then
    media_cache.data = nil
    media_cache.last_update = now
    return nil
  end

  local media = nil
  for _, item in ipairs(data) do
    if item.source:find "Spotify" then
      media = item
      break
    end
  end

  media_cache.data = media or data[1]
  media_cache.last_update = now
  return media_cache.data
end

local function calculate_usable_width(window, pane, Config, width)
  for _ = 1, #window:mux_window():tabs() do
    local tab_title = pane:get_title()
    width.tabs = width.tabs + str.width(str.format_tab_title(pane, tab_title, Config, 25))
  end
  width.usable = width.usable - (width.tabs + width.mode + width.new_button + width.ws)
  return width
end

local function create_battery_cells()
  local battery = wt.battery_info()[1]
  if battery then
    battery.charge_lvl = battery.state_of_charge * 100
    battery.charge_lvl_round = mt.toint(mt.mround(battery.charge_lvl, 10))
    battery.ico = icon.Bat[battery.state][tostring(battery.charge_lvl_round)]
    battery.lvl = math.floor(battery.charge_lvl + 0.5) .. "%"
    battery.full = string.format("%s %s", battery.lvl, battery.ico)
    return { battery.full, battery.lvl, battery.ico }
  end
  return nil
end

local function create_time_cells()
  local time_ico = str.padl(icon.Clock[wt.strftime "%I"])
  return { wt.strftime "%R" .. time_ico }
end

local function create_memory_cells(stats)
  local mem_ico = str.padl(icon.Memory)
  return {
    stats and string.format(
      "MEM %sGB/%sGB%s",
      stats.memory.used,
      stats.memory.total,
      mem_ico
    ) or "N/A",
    stats and string.format("%sGB%s", stats.memory.used, mem_ico) or "N/A",
  }
end

local function create_cpu_cells(stats)
  local cpu_ico = str.padl(icon.Cpu)
  return {
    stats and string.format("CPU %02d%%%s", stats.cpu, cpu_ico) or "N/A",
    stats and string.format("%02d%%%s", stats.cpu, cpu_ico) or "N/A",
  }
end

local media_animation_state = 0
local animation_frames = {
  "▁▃▅",
  "▂▄▆",
  "▃▅▇",
  "▄▆█",
  "▅▇█",
  "▆█▇",
  "▇█▆",
  "█▇▅",
  "▇▆▄",
  "▆▅▃",
  "▅▄▂",
  "▄▃▁",
}

local function create_media_cells(media)
  if media then
    media_animation_state = (media_animation_state + 1) % #animation_frames
    local anim = animation_frames[media_animation_state + 1]

    local truncated_title = #media.title > 30 and media.title:sub(1, 27) .. "..."
      or media.title

    return {
      string.format("%s %s - %s", anim, media.title, media.artist),
      string.format("%s %s - %s", anim, truncated_title, media.artist),
      string.format("%s %s", anim, media.title),
      string.format("%s %s", anim, truncated_title),
    }
  end
  return nil
end

local function handle_modal_prompts(mode, modes, window, rsb, theme, width)
  if mode and modes[mode] then
    local prompt_bg = theme.tab_bar.background
    local map_fg = modes[mode].bg
    local txt_fg = theme.foreground
    local msep = sep.sb.modal

    local key_tbl = require("mappings.modes")[2][mode]
    for idx = 1, #key_tbl do
      local map, _, desc = table.unpack(key_tbl[idx])

      if map:find "%b<>" then
        map = map:gsub("(%b<>)", function(s)
          return s:sub(2, -2)
        end)
      end

      width.prompt = str.width(map .. str.pad(desc)) + modes[mode].pad
      width.usable = width.usable - width.prompt

      if width.usable > 0 and desc ~= "" then
        rsb:append(prompt_bg, txt_fg, "<", { "Bold" })
        rsb:append(prompt_bg, map_fg, map)
        rsb:append(prompt_bg, txt_fg, ">")
        rsb:append(prompt_bg, txt_fg, str.pad(desc), { "Normal", "Italic" })

        local next_map, _, next_desc = table.unpack(key_tbl[idx + 1] or { "", "", "" })
        local next_prompt_len = str.width(next_map .. str.pad(next_desc))
        if idx < #key_tbl and next_prompt_len < width.usable then
          rsb:append(prompt_bg, theme.brights[1], str.padr(msep, 1), { "NoItalic" })
        end
      end
    end

    window:set_right_status(rsb:format())
    return true
  end
  return false
end

local function create_status_cells(Config, theme, stats, media, width)
  local fg = wt.color.parse(theme.ansi[5])
  local palette = { fg:darken(0.15), fg, fg:lighten(0.15), fg:lighten(0.25) }

  local sets = {
    create_cpu_cells(stats),
    create_memory_cells(stats),
    create_time_cells(),
  }

  local battery_cells = create_battery_cells()
  if battery_cells then
    table.insert(sets, battery_cells)
  end

  local media_cells = create_media_cells(media)
  if media_cells then
    table.insert(sets, 1, media_cells)
  end

  local function compute_width(combination, sep_width, pad_width)
    local total_width = 0
    for i = 1, #combination do
      total_width = total_width + str.width(combination[i]) + sep_width + pad_width
    end
    return total_width
  end

  local function find_best_fit(combinations, max_width, sep_width, pad_width)
    local best_fit = nil
    local best_fit_width = 0

    for i = 1, #combinations do
      local total_width = compute_width(combinations[i], sep_width, pad_width)
      if total_width <= max_width and total_width > best_fit_width then
        best_fit = combinations[i]
        best_fit_width = total_width
      end
    end

    return best_fit or {}
  end

  return {
    cells = tbl.reverse(
      find_best_fit(tbl.cartesian(sets), width.usable, str.width(sep.sb.right), 5)
    ),
    palette = palette,
    last_fg = Config.use_fancy_tab_bar and Config.window_frame.active_titlebar_bg
      or theme.tab_bar.background,
  }
end

local function render_status_bar(rsb, status_data, theme)
  for i = 1, #status_data.cells do
    local cell_bg = status_data.palette[i]
    local cell_fg = i == 1 and status_data.last_fg or status_data.palette[i - 1]

    rsb:append(cell_fg, cell_bg, sep.sb.right)
    rsb:append(
      cell_bg,
      theme.tab_bar.background,
      str.pad(status_data.cells[i]),
      { "Bold" }
    )
  end
end

wt.on("update-status", function(window, pane)
  local Config = window:effective_config()
  local Overrides = window:get_config_overrides() or {}
  local theme = Config.color_schemes[Overrides.color_scheme or Config.color_scheme]

  local modes = get_modes(theme)
  local bg, fg = theme.background, theme.ansi[5]

  local pane_dimensions = pane:get_dimensions()
  local win_width = window:get_dimensions().pixel_width

  local usable_space =
    math.floor((win_width * pane_dimensions.cols) / pane_dimensions.pixel_width)

  local width = {
    ws = 0,
    mode = 0,
    tabs = 5,
    prompt = 0,
    usable = usable_space,
    new_button = Config.show_new_tab_button_in_tab_bar and 8 or 0,
  }

  local lsb = StatusBar:new "LeftStatusBar"
  width = create_modal_indicator(window, modes, lsb, bg, width)
  width =
    create_workspace_indicator(window, lsb, theme, bg, window:active_key_table(), width)
  window:set_left_status(lsb:format())

  local rsb = StatusBar:new "RightStatusBar"
  local mode = window:active_key_table()

  width = calculate_usable_width(window, pane, Config, width)

  if handle_modal_prompts(mode, modes, window, rsb, theme, width) then
    return
  end

  local stats = get_system_stats()
  local media = get_media_info()
  local status_data = create_status_cells(Config, theme, stats, media, width)

  render_status_bar(rsb, status_data, theme)
  window:set_right_status(rsb:format())
end)
