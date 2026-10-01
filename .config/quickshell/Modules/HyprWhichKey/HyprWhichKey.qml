pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Components"

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
                bottom: Placement.inset("bottom", 20)
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

                width: grid.implicitWidth + Theme.spacingLarge * 2
                height: grid.implicitHeight + Theme.spacingLarge * 2

                color: Theme.hostSurface
                radius: Theme.radiusWindow
                border.width: 1
                border.color: Theme.popupBorder

                Connections {
                    target: HyprWhichKeyService
                    function onKeybindListChanged() {
                        // Hide entire window immediately to avoid resize artifacts
                        root.shown = false;
                        showTimer.restart();
                    }
                }

                // Keys right-aligned in the first column, descriptions in the second
                GridLayout {
                    id: grid

                    anchors.centerIn: parent
                    columns: 2
                    rowSpacing: Theme.spacingSmall
                    columnSpacing: Theme.spacingBase

                    Repeater {
                        model: HyprWhichKeyService.keybindList

                        Keycap {
                            required property var modelData
                            required property int index

                            Layout.row: index
                            Layout.column: 0
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            text: modelData.keys
                        }
                    }

                    Repeater {
                        model: HyprWhichKeyService.keybindList

                        StyledText {
                            required property var modelData
                            required property int index

                            Layout.row: index
                            Layout.column: 1
                            text: modelData.description
                        }
                    }
                }
            }
        }
    }
}
