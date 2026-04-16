### Dependencies

General: `quickshell-git`, `yq` and must have [base16 themes](https://github.com/byddha/dotfiles/tree/master/.config/base16) in ~/.config/base16

Wifi: `nmcli`

Vpn: `mullvad`, `openfortivpn`

Compositor: `hyprland`

Laptop screen / keyboard brightness: `brightnessctl`

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
