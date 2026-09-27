pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"

Scope {
    id: root

    property bool shown: false

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: whichKey

            required property ShellScreen modelData
            screen: modelData
            visible: root.shown && modelData.name === Compositor.focusedMonitorName

            anchors {
                bottom: true
            }

            margins {
                bottom: 20
            }

            implicitWidth: container.width
            implicitHeight: container.height

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            color: "transparent"

            Connections {
                target: HyprWhichKeyService
                function onVisibleChanged() {
                    if (HyprWhichKeyService.visible)
                        showTimer.restart();
                    else
                        root.shown = false;
                }
            }

            Timer {
                id: showTimer
                interval: 50
                onTriggered: {
                    root.shown = true;
                }
            }

            Rectangle {
                id: container
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom

                width: Math.max(200, columnLayout.implicitWidth + 16)
                height: Math.max(60, columnLayout.implicitHeight + 16)

                color: Theme.colLayer0
                border.color: Theme.colSecondary
                border.width: 2
                radius: 5
                layer.enabled: true  // Force offscreen rendering to eliminate border artifacts

                visible: true
                opacity: visible ? 1 : 0

                Behavior on opacity {
                    OpacityAnimator {
                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }

                ColumnLayout {
                    id: columnLayout
                    anchors.centerIn: parent

                    spacing: 2

                    // Approximate monospace char width so every key column lines up.
                    readonly property real maxKeyWidth: {
                        const charWidth = Theme.whichKeyFontSize * 0.6;
                        let maxWidth = 0;
                        for (const bind of HyprWhichKeyService.keybindList)
                            maxWidth = Math.max(maxWidth, HyprWhichKeyService.getRawKey(bind).length * charWidth);
                        return maxWidth;
                    }

                    Connections {
                        target: HyprWhichKeyService
                        function onKeybindListChanged() {
                            // Hide entire window immediately to avoid resize artifacts
                            root.shown = false;
                            showTimer.restart();
                        }
                    }

                    Repeater {
                        model: HyprWhichKeyService.keybindList

                        KeybindItem {
                            required property var modelData
                            bind: modelData
                            columnWidth: columnLayout.maxKeyWidth
                        }
                    }
                }
            }
        }
    }
}
