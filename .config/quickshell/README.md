### Dependencies

General: `quickshell-git`, `yq` and must have [base16 themes](https://github.com/byddha/dotfiles/tree/master/.config/base16) in ~/.config/base16

Wifi: `nmcli`

Vpn: `mullvad`, `openfortivpn`

Compositor: `hyprland`

Laptop screen / keyboard brightness: `brightnessctl`

Fill monitors in ~/.config/bidshell/config.json, for example:


```json
    "monitors": {
        "DP-3": {
            "forceRotate": false,
            "hdrCapable": true,
            "workspaces": [
                1,
                5
            ]
        },
        "HDMI-A-1": {
            "forceRotate": true,
            "hdrCapable": false,
            "workspaces": [
                6,
                8
            ]
        }
    },

```
