pragma Singleton

import QtQuick
import Quickshell
import "../../Utils"

Singleton {
    id: root

    function init() {
        Logger.info("Service initialized");
    }

    // ==================
    // Volume Icons
    // ==================
    readonly property string volumeMuted: "󰖁"
    readonly property string volumeOff: "󰖁"
    readonly property string volumeLow: "󰕿"
    readonly property string volumeMedium: "󰖀"
    readonly property string volumeHigh: "󰕾"

    // ==================
    // Microphone Icons
    // ==================
    readonly property string micMuted: "󰍭"
    readonly property string micOn: "󰍬"

    // ==================
    // Brightness Icons
    // ==================
    readonly property string brightness: "󰃟"

    // ==================
    // Network Icons
    // ==================
    readonly property string wifiOn: "󰤨"
    readonly property string wifiOff: "󰤭"
    readonly property string network: "󰖩"

    // ==================
    // Bluetooth Icons
    // ==================
    readonly property string bluetoothOn: "󰂯"
    readonly property string bluetoothOff: "󰂲"

    // ==================
    // Device Icons
    // ==================
    readonly property string headphones: "󰋋"
    readonly property string phone: "󰄜"
    readonly property string mouse: "󰍽"
    readonly property string keyboard: "󰌌"
    readonly property string laptop: "󰌢"
    readonly property string controller: "󰖺"

    // ==================
    // Quick Toggle Icons
    // ==================
    readonly property string vpnOn: "󰦝"
    readonly property string vpnOff: "󰦞"
    readonly property string hdrOn: "󰵽"
    readonly property string hdrOff: "󰵾"
    readonly property string dndOn: "󰂛"
    readonly property string dndOff: "󰂚"
    readonly property string idleOn: "󰒲"   // sleep icon - idle mode is on, system can sleep
    readonly property string idleOff: "󰒳"  // no-sleep icon - idle mode is off, system stays awake
    readonly property string screenSnip: "󰹑"
    readonly property string colorPicker: "󰈊"
    readonly property string recordOn: "󰑋"
    readonly property string recordOff: "󰑊"
    readonly property string airplaneOn: "󰀝"
    readonly property string airplaneOff: "󰀞"

    // ==================
    // Media Icons
    // ==================
    readonly property string play: "󰐊"
    readonly property string pause: "󰏤"
    readonly property string skipPrevious: "󰒮"
    readonly property string skipNext: "󰒭"
    readonly property string music: "󰌳"
    readonly property string musicAlt: "󰎈"

    // ==================
    // Power/System Icons
    // ==================
    readonly property string power: "󰣇"
    readonly property string battery: "󰁹"
    readonly property string battery10: "󰁺"
    readonly property string battery20: "󰁻"
    readonly property string battery30: "󰁼"
    readonly property string battery40: "󰁽"
    readonly property string battery50: "󰁾"
    readonly property string battery60: "󰁿"
    readonly property string battery70: "󰂀"
    readonly property string battery80: "󰂁"
    readonly property string battery90: "󰂂"
    readonly property string battery100: "󰁹"
    readonly property string batteryCharging: "󰂄"
    readonly property string batteryCharging10: "󰢜"
    readonly property string batteryCharging20: "󰂆"
    readonly property string batteryCharging30: "󰂇"
    readonly property string batteryCharging40: "󰂈"
    readonly property string batteryCharging50: "󰢝"
    readonly property string batteryCharging60: "󰂉"
    readonly property string batteryCharging70: "󰢞"
    readonly property string batteryCharging80: "󰂊"
    readonly property string batteryCharging90: "󰂋"
    readonly property string batteryCharging100: "󰂅"
    readonly property string batteryAlert: "󰂃"
    readonly property string shutdown: "󰐥"
    readonly property string reboot: "󰜉"
    readonly property string logout: "󰍃"
    readonly property string suspend: "󰒲"

    // ==================
    // Modifier Key Icons
    // ==================
    readonly property string keyCtrl: "󰘴"
    readonly property string keySuper: "󰣇"
    readonly property string keyCaps: "󰪛"
    readonly property string keyWorkspace: "󰆾"

    // ==================
    // Navigation Icons
    // ==================
    readonly property string chevronLeft: ""
    readonly property string chevronRight: ""
    readonly property string today: "󰃶"

    // ==================
    // Notification Icons
    // ==================
    readonly property string bell: "󰂚"
    readonly property string bellOff: "󰂛"

    // ==================
    // Weather Icons (Nerd Font md-weather_*)
    // ==================
    readonly property string weatherSunny: "󰖙"
    readonly property string weatherClear: "󰖙"
    readonly property string weatherNight: "󰖔"
    readonly property string weatherPartlyCloudy: "󰖕"
    readonly property string weatherCloudy: "󰖐"
    readonly property string weatherFog: "󰖑"
    readonly property string weatherRainy: "󰖗"
    readonly property string weatherSnowy: "󰖘"
    readonly property string weatherThunderstorm: "󰖓"
    readonly property string weatherWindy: "󰖝"

    // Weather detail icons
    readonly property string thermometer: "󰔏"
    readonly property string humidity: "󰖌"
    readonly property string wind: "󰖝"
    readonly property string rain: "󰖗"
    readonly property string spinner: ""

    // ==================
    // Misc Icons
    // ==================
    readonly property string menu: "☰"
    readonly property string workspace: ""
    readonly property string device: ""
    readonly property string checkmark: ""
    readonly property string emptyState: ""
    readonly property string cross: "✝"
    readonly property string star: "★"
    readonly property string flag: "⚑"
    readonly property string heart: "♡"
}
