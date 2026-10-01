import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland

ScreencopyView {
    property string windowId

    captureSource: Hyprland.toplevels.values.find(t => `0x${t.address}` === windowId)?.wayland ?? null
    live: false
    constraintSize: Qt.size(width, height)
}
