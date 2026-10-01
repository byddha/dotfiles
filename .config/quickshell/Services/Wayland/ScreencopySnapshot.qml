import QtQuick
import Quickshell.Wayland

ScreencopyView {
    property var screen

    captureSource: screen
    live: false
    paintCursor: false
}
