### Dependencies

General: `quickshell-git`, `libnotify` (`notify-send`), `python-gobject` + `gtk3` (icon lookup)

Compositor: `hyprland` or `niri`

Theme: `~/dotfiles/scripts/theme-set` (writes `~/.cache/theme/dms-colors.json`)

Wifi: `networkmanager` (`nmcli`)

Bluetooth: `bluez`, `blueman` (manager button)

Vpn: `mullvad`, `openfortivpn` (run through `sudo`)

Laptop screen / keyboard brightness: `brightnessctl`

Screenshots and recording: `wl-clipboard`, `swappy`, `tesseract` (+ language data), `curl`, `jq`, `xdg-utils`, `python-pillow`, `wf-recorder`, `hyprpicker`

Media visualizer: `cava`

Peripheral brand lookup: `hwdata`

Game launcher: `steam`

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
