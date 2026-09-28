### Dependencies

General: `quickshell-git`, `libnotify` (`notify-send`), `python-gobject` + `gtk3` (icon lookup)

Compositor: `hyprland` or `niri`

Theme: `~/dotfiles/scripts/theme-set` (writes `~/.cache/theme/dms-colors.json`)

Wifi: `networkmanager` (`nmcli`)

Bluetooth: `bluez`, `blueman` (manager button)

Vpn: `mullvad`, `openfortivpn` (run through `sudo`)

Laptop screen / keyboard brightness: `brightnessctl`

Screenshots and recording: `wl-clipboard`, `swappy`, `tesseract` (+ language data), `curl`, `jq`, `xdg-utils`, `python-pillow`, `gpu-screen-recorder`, `hyprpicker`

Media visualizer: `cava`

Peripheral brand lookup: `hwdata`

Game launcher: `steam`

Fonts: none to install; Geist and Lucide are bundled in `assets/fonts`. Icons Lucide lacks (HDR, from Tabler) are added to the bundled `lucide.ttf` by `assets/fonts/lucide/extra/add-icons.py`; rerun it after updating Lucide

Fill monitors in ~/.config/bidshell/config.json. Keys are the monitor `model` from EDID (check with `hyprctl monitors` → `model:` line), for example:


```json
    "monitors": {
        "MO34WQC2": {
            "hdrCapable": true,
            "primary": true,
            "workspaces": [1, 5]
        },
        "0x1920": {
            "hdrCapable": false,
            "workspaces": [6, 8]
        }
    },

```

Placement, in the same file. Everything keeps clear of the bar on whichever side it is:

```json
    "bar": { "position": "top", "floating": false },
    "notifications": { "position": "bottom-right" },
    "sidebar": { "side": "right" },
    "osd": { "position": "right" },
```

- `bar.position`: `top`, `bottom`, `left`, `right`; `floating` keeps it off the screen edges
- `notifications.position`: `top-left`, `top-center`, `top-right`, `bottom-left`, `bottom-center`, `bottom-right`
- `sidebar.side`, `osd.position`: `left`, `right`
