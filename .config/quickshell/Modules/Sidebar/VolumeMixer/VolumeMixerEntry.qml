import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../Config"
import "../../../Components"
import "../../../Services"
import "../../../Utils"
import Quickshell.Services.Pipewire

Item {
    id: root

    required property PwNode node
    property bool isGroupChild: false

    signal volumeChanged(real value)
    signal muteToggled()

    implicitHeight: contentLayout.implicitHeight

    // Keep node connection alive
    PwObjectTracker {
        objects: [root.node]
    }

    // Helper function to extract app class from PipeWire node
    function getAppClass(node) {
        if (!node) return "unknown"

        const binary = node.properties["application.process.binary"]
        if (binary) return binary

        const appName = node.properties["application.name"]
        if (appName) return appName.toLowerCase()

        return "unknown"
    }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: -2

        // App info row (icon + name)
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.isGroupChild ? 28 : 0
            spacing: Theme.spacingBase

            Text {
                text: AppIcons.getIcon(root.getAppClass(root.node))
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 20
                color: Theme.textColor
                visible: !root.isGroupChild
                Layout.alignment: Qt.AlignVCenter
            }

            StyledText {
                Layout.fillWidth: true
                text: {
                    if (root.isGroupChild) {
                        return root.node?.properties["media.name"] || "audio stream";
                    }
                    const appName = Audio.appNodeDisplayName(root.node);
                    const mediaName = root.node?.properties["media.name"];
                    return mediaName ? `${appName} • ${mediaName}` : appName;
                }
                font.pixelSize: Theme.fontSizeSmall
                font.strikeout: root.node?.audio.muted ?? false
                color: Theme.textSecondary
                elide: Text.ElideRight
            }
        }

        // Volume slider
        Slider {
            Layout.fillWidth: true
            Layout.leftMargin: root.isGroupChild ? 28 : 0

            value: root.node?.audio.volume ?? 0
            from: 0
            to: 1.5
            isMuted: root.node?.audio.muted ?? false

            onMoved: newValue => {
                if (root.node) {
                    root.node.audio.volume = newValue;
                    root.volumeChanged(newValue);
                    Logger.info(`${Audio.appNodeDisplayName(root.node)} volume: ${Math.round(newValue * 100)}%`);
                }
            }

            onRightClicked: {
                if (root.node) {
                    root.node.audio.muted = !root.node.audio.muted;
                    root.muteToggled();
                    Logger.info(`${Audio.appNodeDisplayName(root.node)} ${root.node.audio.muted ? 'muted' : 'unmuted'}`);
                }
            }
        }
    }
}
