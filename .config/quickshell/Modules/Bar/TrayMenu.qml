pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"

// A tray app's menu. Submenus replace the list, with a Back row on top.
BarPopout {
    id: root

    property var menu: null

    WlrLayershell.namespace: "bidshell:tray-menu"
    padding: 6

    function openMenu(trayMenu, opener, fromPopout) {
        menu = trayMenu;
        stack.clear();
        stack.push(levelComponent, {
            handle: trayMenu
        });
        openFrom(opener, fromPopout);
    }

    StackView {
        id: stack

        anchors.fill: parent
        implicitWidth: currentItem?.implicitWidth ?? 200
        implicitHeight: currentItem?.implicitHeight ?? 34
        pushEnter: Transition {}
        pushExit: Transition {}
        popEnter: Transition {}
        popExit: Transition {}
    }

    Component {
        id: levelComponent

        Item {
            id: level

            required property var handle
            property bool isSubmenu: false

            implicitWidth: Math.min(360, Math.max(200, list.implicitWidth))
            implicitHeight: list.implicitHeight

            QsMenuOpener {
                id: opener

                menu: level.handle
            }

            ColumnLayout {
                id: list

                anchors.fill: parent
                spacing: 1

                BarMenuRow {
                    visible: level.isSubmenu
                    icon: Lucide.chevronLeft
                    label: "Back"
                    onActivated: stack.pop()
                }

                Repeater {
                    model: opener.children

                    Item {
                        id: entry

                        required property var modelData

                        Layout.fillWidth: true
                        implicitWidth: row.implicitWidth
                        implicitHeight: modelData.isSeparator ? 9 : row.implicitHeight

                        Rectangle {
                            visible: entry.modelData.isSeparator
                            anchors.verticalCenter: parent.verticalCenter
                            x: 6
                            width: parent.width - 12
                            height: 1
                            color: Theme.outlineVariant
                        }

                        BarMenuRow {
                            id: row

                            visible: !entry.modelData.isSeparator
                            width: parent.width
                            enabled: entry.modelData.enabled
                            label: entry.modelData.text
                            submenu: entry.modelData.hasChildren
                            iconSource: entry.modelData.icon
                            icon: {
                                if (entry.modelData.buttonType === QsMenuButtonType.CheckBox)
                                    return entry.modelData.checkState === Qt.Checked ? Lucide.squareCheck : Lucide.square;
                                if (entry.modelData.buttonType === QsMenuButtonType.RadioButton)
                                    return entry.modelData.checkState === Qt.Checked ? Lucide.circleDot : Lucide.circle;
                                return "";
                            }
                            onActivated: {
                                if (entry.modelData.hasChildren) {
                                    stack.push(levelComponent, {
                                        handle: entry.modelData,
                                        isSubmenu: true
                                    });
                                    return;
                                }
                                entry.modelData.triggered();
                                root.hidePanel();
                            }
                        }
                    }
                }
            }
        }
    }
}
