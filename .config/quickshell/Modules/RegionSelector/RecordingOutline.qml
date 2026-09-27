import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"

// Thin red frame around the area being recorded, drawn just outside it so the recording never
// contains it. Takes no input: clicks and keys go to whatever is under it.
Scope {
    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: window

            required property ShellScreen modelData
            readonly property var monitorInfo: Compositor.monitorForScreen(modelData)
            readonly property rect local: Qt.rect(Recording.region.x - (monitorInfo?.x ?? 0), Recording.region.y - (monitorInfo?.y ?? 0), Recording.region.width, Recording.region.height)

            screen: modelData
            visible: Recording.recording && Recording.region.width > 0 && local.x < modelData.width && local.y < modelData.height && local.x + local.width > 0 && local.y + local.height > 0

            WlrLayershell.namespace: "bidshell:recordingOutline"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                x: window.local.x - 3
                y: window.local.y - 3
                width: window.local.width + 6
                height: window.local.height + 6
                color: "transparent"
                border.color: Qt.rgba(0, 0, 0, 0.35)
                border.width: 1

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    color: "transparent"
                    border.color: Theme.accentRed
                    border.width: 2
                }
            }
        }
    }
}
