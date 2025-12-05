import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Config"
import "../../Services"
import "../../Utils"
import ".."
import "notification_utils.js" as NotifUtils

MouseArea {
    id: root

    required property var notificationObject
    property bool popup: false

    // Detect if this is a media player notification
    readonly property bool isMediaNotification: {
        const appName = (notificationObject.appName || "").toLowerCase();
        const mediaApps = ["spotify", "tidal", "tidal-hifi", "vlc", "rhythmbox", "lollypop", "elisa", "amberol", "g4music", "music", "clementine", "strawberry", "audacious", "deadbeef", "cmus", "mpd", "ncspot", "playerctl"];
        return mediaApps.some(app => appName.includes(app));
    }

    // Show MediaCard only for popup media notifications
    readonly property bool showMediaCard: popup && isMediaNotification

    // Find the MPRIS player that matches this notification's app
    readonly property var matchingPlayer: {
        if (!isMediaNotification)
            return null;
        const appName = (notificationObject.appName || "").toLowerCase();
        return MprisController.availablePlayers.find(p => (p.identity || "").toLowerCase().includes(appName) || appName.includes((p.identity || "").toLowerCase())) || MprisController.activePlayer;
    }

    hoverEnabled: true
    acceptedButtons: Qt.RightButton

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            Quickshell.clipboardText = notificationObject.body || "";
        }
    }

    implicitHeight: showMediaCard ? (mediaCard.implicitHeight + Theme.spacingBase) : background.implicitHeight

    function processNotificationBody(body, appName) {
        let processedBody = body;

        // Clean Chromium-based browsers notifications - remove first line
        if (appName) {
            const lowerApp = appName.toLowerCase();
            const chromiumBrowsers = ["brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge", "zen"];

            if (chromiumBrowsers.some(name => lowerApp.includes(name))) {
                const lines = body.split('\n\n');

                if (lines.length > 1 && lines[0].startsWith('<a')) {
                    processedBody = lines.slice(1).join('\n\n');
                }
            }
        }

        return processedBody;
    }

    // MediaCard for popup media notifications (replaces entire notification)
    MediaCard {
        id: mediaCard
        anchors.top: parent.top
        anchors.topMargin: Theme.spacingBase
        width: parent.width
        visible: root.showMediaCard
        player: root.matchingPlayer
        compact: false
        showControls: true
        implicitHeight: 100
    }

    // Normal notification background (for non-media or sidebar)
    Rectangle {
        id: background
        width: parent.width
        anchors.left: parent.left
        radius: Theme.radiusBase
        visible: !root.showMediaCard
        color: {
            if (notificationObject.urgency === "critical") {
                return ColorUtils.mix(Theme.accentRed, Theme.colLayer1, 0.15);
            }
            return Theme.colLayer1;
        }
        border.width: 2
        border.color: Theme.colLayer2

        implicitHeight: Math.max(contentColumn.implicitHeight + Theme.spacingBase * 4, 130)

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        RowLayout {
            id: mainRow
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.spacingBase * 1.5
            anchors.rightMargin: Theme.spacingBase * 1.5
            anchors.topMargin: Theme.spacingBase * 1.5
            anchors.bottomMargin: Theme.spacingBase
            spacing: Theme.spacingBase

            // Left column: Icon
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.spacingBase / 2

                // Image/Icon container (no background)
                Item {
                    id: iconContainer
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48

                    // Notification image (album art, screenshots, etc.)
                    // Only load qsimage:// URLs for popups (they expire after popup closes)
                    Image {
                        id: notifImage
                        anchors.fill: parent
                        source: {
                            const img = root.notificationObject.image || "";
                            // qsimage:// URLs are temporary - only valid for popups
                            if (!root.popup && img.startsWith("image://qsimage/")) {
                                return "";
                            }
                            return img;
                        }
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: status === Image.Ready
                    }

                    // App icon (when no notification image)
                    Image {
                        id: appIconImage
                        anchors.fill: parent
                        source: resolvedIconPath
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        visible: notifImage.status !== Image.Ready && status === Image.Ready

                        // Use app icon if provided, otherwise use dialog-information (freedesktop standard)
                        property string iconName: root.notificationObject.appIcon || "dialog-information"
                        property string resolvedIconPath: IconResolver.getIconPath(iconName)

                        Connections {
                            target: IconResolver
                            function onIconResolved(name, path) {
                                if (name === appIconImage.iconName) {
                                    appIconImage.resolvedIconPath = path;
                                }
                            }
                        }
                    }

                    // Nerd Font fallback (when no images available)
                    Text {
                        anchors.centerIn: parent
                        visible: notifImage.status !== Image.Ready && appIconImage.status !== Image.Ready
                        text: AppIcons.getIcon((root.notificationObject.appName || "").toLowerCase().replace(/\s+/g, "-"))
                        font.family: Theme.fontFamilyIcons
                        font.pixelSize: 28
                        color: root.notificationObject.urgency === "critical" ? Theme.accentRed : Theme.textColor

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }
                }
            }

            // Content column
            ColumnLayout {
                id: contentColumn
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.spacingBase / 2

                // Summary row
                RowLayout {
                    id: summaryRow
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingBase / 2
                    implicitHeight: summaryText.implicitHeight
                    spacing: Theme.spacingBase

                    StyledText {
                        id: summaryText
                        Layout.fillWidth: true
                        font.pixelSize: Theme.fontSizeBase
                        font.bold: true
                        color: Theme.textColor
                        elide: Text.ElideRight
                        text: root.notificationObject.summary || ""
                    }

                    StyledText {
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textSecondary
                        opacity: 0.7
                        text: {
                            const date = new Date(root.notificationObject.time)
                            const hours = String(date.getHours()).padStart(2, '0')
                            const minutes = String(date.getMinutes()).padStart(2, '0')
                            const seconds = String(date.getSeconds()).padStart(2, '0')
                            return `${hours}:${minutes}:${seconds}`
                        }
                    }
                }

                // Notification body
                StyledText {
                    id: notificationBodyText
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0  // Force it to respect fillWidth
                    font.pixelSize: Theme.fontSizeBase
                    color: Theme.textSecondary
                    wrapMode: Text.Wrap
                    textFormat: Text.RichText
                    text: {
                        const body = notificationObject.body || "";
                        return `<style>img{max-width:300px;}</style>` + `${processNotificationBody(body, notificationObject.appName || notificationObject.summary).replace(/\n/g, "<br/>")}`;
                    }

                    onLinkActivated: link => {
                        Qt.openUrlExternally(link);
                        Settings.sidebarVisible = false;
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }

                // Spacer to push buttons to bottom
                Item {
                    Layout.fillHeight: true
                }

                // Action buttons
                RowLayout {
                    id: actionRowLayout
                    Layout.fillWidth: true
                    spacing: Theme.spacingBase / 2
                    visible: notificationObject.actions.length > 0

                    Repeater {
                        model: notificationObject.actions
                        Button {
                            Layout.fillWidth: true
                            text: modelData.text
                            font.pixelSize: Theme.fontSizeSmall
                            onClicked: {
                                Notifications.attemptInvokeAction(notificationObject.notificationId, modelData.identifier);
                            }
                        }
                    }
                }
            }  // End contentColumn
        }  // End mainRow
    }  // End background
}  // End root
