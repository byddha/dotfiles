import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Utils"

Scope {
    PanelWindow {
        id: whichKey

        screen: Quickshell.screens[0]
        visible: Config?.options.hyprWhichKey.enabled && Settings.hyprWhichKeyVisible 

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
                if (HyprWhichKeyService.visible) {
                    // Show window with delay after content is ready
                    showTimer.restart();
                } else {
                    // Hide immediately
                    Settings.hyprWhichKeyVisible = false;
                }
            }
        }

        Timer {
            id: fadeInTimer
            interval: 10
            onTriggered: {
                container.visible = true;
            }
        }

        Timer {
            id: showTimer
            interval: 50
            onTriggered: {
                Settings.hyprWhichKeyVisible = true;
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

            Behavior on width {
                enabled: false
            }

            Behavior on height {
                enabled: false
            }

            ColumnLayout {
                id: columnLayout
                anchors.centerIn: parent

                spacing: 2

                Component.onCompleted: populateList()

                Connections {
                    target: HyprWhichKeyService
                    function onKeybindListChanged() {
                        // Hide entire window immediately to avoid resize artifacts
                        Settings.hyprWhichKeyVisible = false;
                        columnLayout.populateList();
                        // Show window after layout settles
                        showTimer.restart();
                    }
                }

                function populateList() {
                    // Clean up existing children
                    const childrenToDestroy = [];
                    for (let i = columnLayout.children.length - 1; i >= 0; i--) {
                        const child = columnLayout.children[i];
                        if (child) {
                            childrenToDestroy.push(child);
                            child.parent = null;
                        }
                    }

                    for (const child of childrenToDestroy) {
                        if (child)
                            child.destroy();
                    }

                    // Calculate single global max key width for alignment
                    // Scale character width based on font size (approximate ratio)
                    Logger.info(JSON.stringify(Config.options.hyprWhichKey));
                    const charWidth = Config.options.hyprWhichKey.fontSize * 0.6;
                    let maxKeyWidth = 0;
                    for (const bind of HyprWhichKeyService.keybindList) {
                        const keyText = HyprWhichKeyService.getRawKey(bind);
                        maxKeyWidth = Math.max(maxKeyWidth, keyText.length * charWidth);
                    }

                    // Create keybind items
                    for (const bind of HyprWhichKeyService.keybindList) {
                        const keybindComponent = Qt.createComponent("KeybindItem.qml");
                        const keybind = keybindComponent.createObject(columnLayout, {
                            bind: bind,
                            columnWidth: maxKeyWidth
                        });
                    }

                    //Debug
                    Logger.info(`Populated ${HyprWhichKeyService.keybindList.length} keybinds, maxKeyWidth: ${maxKeyWidth}`);
                }
            }
        }
    }
}
