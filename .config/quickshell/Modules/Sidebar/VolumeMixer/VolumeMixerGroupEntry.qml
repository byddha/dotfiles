pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../Config"
import "../../../Components"
import "../../../Services"

// An app with one stream is a plain entry; with several, a parent row (slider moves all streams)
// and its streams in a tree. While linked, moving or muting one stream does the same to the others.
Item {
    id: root

    required property var group
    property bool linked: true
    readonly property bool isGroup: group.nodes.length > 1
    readonly property real groupVolume: Math.max(0, ...group.nodes.map(n => n?.audio?.volume ?? 0))
    readonly property bool groupMuted: group.nodes.every(n => n?.audio?.muted ?? false)

    readonly property int rowMargin: 8
    // Streams line up under the app name; the tree trunk runs under the app icon's center
    readonly property real streamIndent: rowMargin + avatar.width + parentRow.spacing
    readonly property real trunkX: rowMargin + avatar.width / 2

    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Loader {
            Layout.fillWidth: true
            active: !root.isGroup && root.group.nodes.length > 0
            visible: active
            sourceComponent: VolumeMixerEntry {
                node: root.group.nodes[0]
            }
        }

        RowLayout {
            id: parentRow
            visible: root.isGroup
            Layout.fillWidth: true
            Layout.leftMargin: root.rowMargin
            Layout.rightMargin: root.rowMargin
            Layout.topMargin: 6
            spacing: 12

            AppAvatar {
                id: avatar
                node: root.group.nodes[0]

                // Start of the tree trunk, from under the icon to the first stream
                Rectangle {
                    x: parent.width / 2
                    y: parent.height
                    width: 1
                    height: parentRow.height - parent.y - parent.height
                    color: Theme.outlineVariant
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSmall

                    // As DMS DankLauncherV2 SectionHeader: the name elides only when the suffix would not fit
                    Row {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        StyledText {
                            width: Math.min(implicitWidth, parent.width - streamCount.implicitWidth)
                            text: avatar.entry?.name || root.group.appName
                            font.pixelSize: Theme.fontSizeSmall
                            elide: Text.ElideRight
                        }

                        StyledText {
                            id: streamCount
                            text: ` · ${root.group.nodes.length} streams`
                            role: "secondary"
                            font.pixelSize: Theme.fontSizeTiny
                        }
                    }

                    // In the title line, so the group slider is as wide as the stream sliders
                    IconButton {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: Theme.radiusSmall
                        icon: root.linked ? Lucide.link : Lucide.unlink
                        iconSize: Theme.iconSizeSmall
                        toggled: root.linked
                        onClicked: root.linked = !root.linked
                    }
                }

                Slider {
                    Layout.fillWidth: true
                    implicitHeight: 24
                    value: root.groupVolume
                    to: 1.5
                    showMuteIcon: true
                    isMuted: root.groupMuted
                    onMoved: newValue => {
                        for (const n of root.group.nodes)
                            n.audio.volume = newValue;
                    }
                    onRightClicked: {
                        const muted = !root.groupMuted;
                        for (const n of root.group.nodes)
                            n.audio.muted = muted;
                    }
                }
            }
        }

        ColumnLayout {
            visible: root.isGroup
            Layout.fillWidth: true
            Layout.leftMargin: root.streamIndent
            spacing: 0

            Repeater {
                id: streamRepeater
                model: ScriptModel {
                    values: root.group.nodes
                }

                VolumeMixerEntry {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    node: modelData
                    isGroupChild: true
                    treeX: root.trunkX - root.streamIndent
                    isLastChild: index === streamRepeater.count - 1

                    onVolumeChanged: value => {
                        if (!root.linked)
                            return;
                        for (const n of root.group.nodes) {
                            if (n !== node)
                                n.audio.volume = value;
                        }
                    }

                    onMuteToggled: {
                        if (!root.linked)
                            return;
                        for (const n of root.group.nodes) {
                            if (n !== node)
                                n.audio.muted = node.audio.muted;
                        }
                    }
                }
            }
        }
    }
}
