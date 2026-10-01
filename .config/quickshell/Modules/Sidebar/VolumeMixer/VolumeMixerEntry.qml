import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../../Config"
import "../../../Components"
import "../../../Services"

// One audio stream: app row (avatar · name over slider) or, inside a group, stream title over slider
Item {
    id: root

    required property PwNode node
    property bool isGroupChild: false
    // Tree connector for a group child: x of the group's trunk relative to this entry, and whether it ends here
    property real treeX: 0
    property bool isLastChild: false
    readonly property real titleCenterY: row.y + textColumn.y + title.y + title.height / 2

    signal volumeChanged(real value)
    signal muteToggled

    function toggleMute() {
        if (!node)
            return;
        node.audio.muted = !node.audio.muted;
        muteToggled();
    }

    implicitHeight: row.implicitHeight + (isGroupChild ? 4 : 12)

    PwObjectTracker {
        objects: [root.node]
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.toggleMute()
    }

    // Trunk down to this stream's elbow, and on to the next stream unless this is the last one
    Rectangle {
        visible: root.isGroupChild && !root.isLastChild
        x: root.treeX
        y: root.titleCenterY
        width: 1
        height: root.height - root.titleCenterY
        color: Theme.outlineVariant
    }

    // Rounded elbow from the trunk into the title line; only the left and bottom edges stay inside the clip
    Item {
        visible: root.isGroupChild
        x: root.treeX
        width: -root.treeX - 8
        height: root.titleCenterY + 1
        clip: true

        Rectangle {
            y: -6
            width: parent.width + 6
            height: parent.height + 6
            radius: 6
            color: "transparent"
            border.width: 1
            border.color: Theme.outlineVariant
        }
    }

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.isGroupChild ? 0 : 8
        anchors.rightMargin: 8
        spacing: 12

        AppAvatar {
            id: avatar
            visible: !root.isGroupChild
            node: root.node
        }

        ColumnLayout {
            id: textColumn
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: title
                Layout.fillWidth: true
                text: root.isGroupChild ? (root.node?.properties["media.name"] || "Audio stream") : (avatar.entry?.name || Audio.appNodeDisplayName(root.node))
                role: root.isGroupChild ? "secondary" : "primary"
                font.pixelSize: root.isGroupChild ? Theme.fontSizeTiny : Theme.fontSizeSmall
                elide: Text.ElideRight
            }

            Slider {
                Layout.fillWidth: true
                implicitHeight: 24
                value: root.node?.audio.volume ?? 0
                to: 1.5
                showMuteIcon: true
                isMuted: root.node?.audio.muted ?? false
                onMoved: newValue => {
                    if (!root.node)
                        return;
                    root.node.audio.volume = newValue;
                    root.volumeChanged(newValue);
                }
                onRightClicked: root.toggleMute()
            }
        }
    }
}
