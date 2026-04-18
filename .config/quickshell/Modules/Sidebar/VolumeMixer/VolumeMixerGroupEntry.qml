import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../Config"
import "../../../Components"
import "../../../Services"
import "../../../Utils"

Item {
    id: root

    required property var group
    property bool linked: true
    readonly property bool isGroup: group.nodes.length > 1

    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // Group header (icon + app name + link toggle) — only for multi-stream
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingBase
            visible: root.isGroup

            Text {
                text: AppIcons.getIcon(root.group.appKey)
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 20
                color: Theme.textColor
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                Layout.fillWidth: true
                text: root.group.appName
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
                elide: Text.ElideRight
            }

            Item {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: root.linked ? Icons.link : Icons.linkOff
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: 14
                    color: root.linked ? Theme.primary : Theme.textSecondary

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.linked = !root.linked
                }
            }
        }

        // Stream entries with link indicator
        Item {
            Layout.fillWidth: true
            implicitHeight: streamColumn.implicitHeight
            visible: root.isGroup

            // Tree connector lines
            Item {
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 19
                opacity: root.linked ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                // Vertical trunk line (from top to last entry's midpoint)
                Rectangle {
                    id: trunk
                    width: 2
                    radius: 1
                    anchors.left: parent.left
                    anchors.top: parent.top
                    color: Theme.primary

                    // Extend to the vertical center of the last entry
                    height: {
                        const count = streamRepeater.count;
                        if (count === 0)
                            return 0;
                        const lastItem = streamRepeater.itemAt(count - 1);
                        if (!lastItem)
                            return 0;
                        return lastItem.y + lastItem.height / 2;
                    }
                }

                // Horizontal branches to each entry
                Repeater {
                    id: branchRepeater
                    model: streamRepeater.count

                    Rectangle {
                        required property int index
                        height: 2
                        radius: 1
                        width: parent.width - 2
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        color: Theme.primary
                        y: {
                            const item = streamRepeater.itemAt(index);
                            return item ? item.y + item.height / 2 - 1 : 0;
                        }
                    }
                }
            }

            ColumnLayout {
                id: streamColumn
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0

                Repeater {
                    id: streamRepeater
                    model: ScriptModel {
                        values: root.group.nodes
                    }

                    VolumeMixerEntry {
                        required property var modelData
                        Layout.fillWidth: true
                        node: modelData
                        isGroupChild: true

                        onVolumeChanged: value => {
                            if (root.linked) {
                                for (const n of root.group.nodes) {
                                    if (n !== node)
                                        n.audio.volume = value;
                                }
                            }
                        }

                        onMuteToggled: {
                            if (root.linked) {
                                const muted = node.audio.muted;
                                for (const n of root.group.nodes) {
                                    if (n !== node)
                                        n.audio.muted = muted;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Single stream (no group)
        Repeater {
            model: ScriptModel {
                values: root.isGroup ? [] : root.group.nodes
            }

            VolumeMixerEntry {
                required property var modelData
                Layout.fillWidth: true
                node: modelData
            }
        }
    }
}
