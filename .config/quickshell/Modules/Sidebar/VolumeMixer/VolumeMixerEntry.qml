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

    implicitHeight: contentLayout.implicitHeight

    // Keep node connection alive
    PwObjectTracker {
        objects: [root.node]
    }

    // Helper function to extract app class from PipeWire node
    function getAppClass(node) {
        if (!node) return "unknown"

        // Try application.process.binary first (most reliable)
        const binary = node.properties["application.process.binary"]
        if (binary) return binary

        // Fallback to application.name (lowercased)
        const appName = node.properties["application.name"]
        if (appName) return appName.toLowerCase()

        return "unknown"
    }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: -2  // Negative spacing for compact design

        // App info row (icon + name)
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingBase

            // App icon
            Text {
                text: AppIcons.getIcon(root.getAppClass(root.node))
                font.family: Theme.fontFamilyIcons
                font.pixelSize: 20
                color: Theme.textColor

                Layout.alignment: Qt.AlignVCenter
            }

            // App name text
            StyledText {
                Layout.fillWidth: true
                text: {
                    const appName = Audio.appNodeDisplayName(root.node);
                    const mediaName = root.node?.properties["media.name"];
                    return mediaName ? `${appName} • ${mediaName}` : appName;
                }
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textSecondary
                elide: Text.ElideRight
            }
        }

        // Volume slider
        Slider {
            Layout.fillWidth: true

            value: root.node?.audio.volume ?? 0
            from: 0
            to: 1.5  // Allow 150% volume
            isMuted: root.node?.audio.muted ?? false

            onMoved: newValue => {
                if (root.node) {
                    root.node.audio.volume = newValue;
                    Logger.info(`${Audio.appNodeDisplayName(root.node)} volume: ${Math.round(newValue * 100)}%`);
                }
            }

            onRightClicked: {
                if (root.node) {
                    root.node.audio.muted = !root.node.audio.muted;
                    Logger.info(`${Audio.appNodeDisplayName(root.node)} ${root.node.audio.muted ? 'muted' : 'unmuted'}`);
                }
            }
        }
    }
}
