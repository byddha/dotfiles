import ".."
import "../../Config"
import "../../Services"
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

// Clone of DankMaterialShell's NotificationCard.qml with DMS's default metrics (non-compact, default font sizes).
// popup: true adds the NotificationPopup wrapper parts (shadow, border, timeout rail, hover pause, close button);
// popup: false is the history look of Center/HistoryNotificationCard.qml.
Item {
    id: root

    required property var notificationObject
    property bool popup: false
    property bool showActions: popup
    property bool showClose: popup
    property string dismissText: popup ? "Clear" : "Dismiss"
    // History sits on a surface_container card; one step up keeps the grouped cards apart even in
    // themes where surface_container equals the background
    property color surfaceColor: popup ? ThemeService.background : Theme.chipSurface
    property color chipColor: popup ? Theme.chipSurface : Theme.chipSurfaceNested
    // Grouped list corners (DMS groupedListOuterRadius / groupedListInnerRadius), used in history.
    property bool firstInGroup: true
    property bool lastInGroup: true

    // DMS NotificationMetrics / Theme tokens
    readonly property real cardPadding: 12
    readonly property real appIconSize: 36
    readonly property real iconSpacing: 12
    readonly property real contentSpacing: 4
    readonly property real controlSize: 32
    readonly property real actionHeight: 40
    readonly property real actionPadding: 8
    readonly property real thumbnailSize: 56
    readonly property real imageMaxHeight: 224
    readonly property real railHeight: 4
    readonly property int collapsedLines: 2
    readonly property int summarySize: Theme.fontSizeBase
    readonly property int bodySize: Theme.fontSizeTiny
    // DMS cornerRadiusM relative to its window radius (m/l = 12/16), scaled to ours.
    readonly property real cornerRadiusM: Math.round(Theme.radiusWindow * 0.75)
    readonly property real popupRadius: Theme.radiusWindow
    readonly property real innerRadius: Math.round(Theme.radiusWindow * 0.25)

    readonly property bool critical: notificationObject.urgency === NotificationUrgency.Critical
    readonly property Timer timer: popup ? notificationObject.timer : null
    readonly property real railClearance: timeoutBar.active ? 8 : 0

    // qsimage:// images only live as long as the sender's notification, so history skips them.
    readonly property string contentImageSource: {
        const image = Notifications.contentImageSource(notificationObject);
        return !popup && image.startsWith("image://qsimage/") ? "" : image;
    }

    property bool descriptionExpanded: false
    readonly property bool hasMoreText: bodyText.truncated || summaryText.truncated
    readonly property bool hasContentImage: imagePreview.visible
    readonly property bool canExpand: hasMoreText || hasContentImage || descriptionExpanded
    readonly property real cardHeight: Math.max(appIconSize, content.implicitHeight) + cardPadding * 2

    property int timeTick: 0
    readonly property string timeStr: {
        root.timeTick;
        const time = new Date(notificationObject.time);
        const now = new Date();
        const minutes = Math.floor((now.getTime() - time.getTime()) / 60000);
        if (minutes < 1)
            return "now";
        if (minutes < 60)
            return `${minutes}m ago`;
        const timeStr = Qt.formatTime(time, "HH:mm");
        const nowDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const timeDate = new Date(time.getFullYear(), time.getMonth(), time.getDate());
        if (nowDate.getTime() === timeDate.getTime())
            return timeStr;
        return `${time.toLocaleDateString(Qt.locale(), "dddd")}, ${timeStr}`;
    }

    readonly property string htmlBody: {
        const body = notificationObject.body || "";
        if (/<\/?[a-z][\s\S]*>/i.test(body))
            return body.replace(/\n/g, "<br/>");
        return body.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/(https?:\/\/[^\s<]+)/g, "<a href=\"$1\">$1</a>").replace(/\n/g, "<br/>");
    }

    function closePopup() {
        timer?.stop();
        Notifications.timeoutNotification(notificationObject.notificationId);
    }

    function invokeAction(action) {
        Notifications.attemptInvokeAction(notificationObject.notificationId, action.identifier);
    }

    implicitHeight: cardHeight + railClearance
    onTimerChanged: Qt.callLater(timeoutBar.sync)

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.timeTick++
    }

    RectangularShadow {
        visible: root.popup
        anchors.fill: cardSurface
        radius: cardSurface.radius
        blur: 8
        offset: Qt.vector2d(0, 4)
        color: Qt.rgba(0, 0, 0, 0.25)
    }

    Rectangle {
        id: cardSurface

        anchors.fill: parent
        radius: root.popup ? root.popupRadius : root.innerRadius
        topLeftRadius: root.popup || root.firstInGroup ? root.popupRadius : root.innerRadius
        topRightRadius: topLeftRadius
        bottomLeftRadius: root.popup || root.lastInGroup ? root.popupRadius : root.innerRadius
        bottomRightRadius: bottomLeftRadius
        color: root.surfaceColor
        clip: true

        HoverHandler {
            onHoveredChanged: {
                if (!timeoutBar.active)
                    return;
                if (hovered)
                    root.timer.stop();
                else if (root.notificationObject.popup)
                    root.timer.restart();
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    Quickshell.clipboardText = root.notificationObject.body || "";
                    return;
                }
                if (root.canExpand) {
                    root.descriptionExpanded = !root.descriptionExpanded;
                    return;
                }
                if (!root.popup)
                    return;
                const actions = root.notificationObject.actions || [];
                if (actions.length > 0) {
                    root.invokeAction(actions[0]);
                    return;
                }
                root.closePopup();
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -root.railClearance / 2
            width: 2
            height: root.cardHeight - root.cardPadding * 2
            radius: width / 2
            color: Theme.primary
            visible: root.critical
        }

        Item {
            id: iconBox

            x: root.cardPadding
            y: root.cardPadding
            width: root.appIconSize
            height: width

            Image {
                id: appImage

                anchors.fill: parent
                asynchronous: true
                smooth: true
                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(root.appIconSize * 2, root.appIconSize * 2)
                source: Notifications.appIconSource(root.notificationObject)
                visible: status === Image.Ready
            }

            Rectangle {
                anchors.fill: parent
                visible: !appImage.visible
                radius: width / 2
                color: Theme.secondaryContainer

                StyledText {
                    anchors.centerIn: parent
                    text: (root.notificationObject.appName || "?").charAt(0).toUpperCase()
                    font.pixelSize: Math.round(parent.width * 0.45)
                    color: Theme.secondaryContainerText
                }
            }
        }

        Column {
            id: content

            anchors.left: iconBox.right
            anchors.leftMargin: root.iconSpacing
            anchors.right: parent.right
            anchors.rightMargin: root.cardPadding
            y: root.cardPadding
            spacing: root.contentSpacing

            Item {
                width: parent.width
                height: root.controlSize

                StyledText {
                    anchors.left: parent.left
                    anchors.right: controls.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    role: "secondary"
                    text: (root.notificationObject.appName || "") + " · " + root.timeStr
                    font.pixelSize: Theme.fontSizeTiny
                    elide: Text.ElideRight
                }

                Row {
                    id: controls

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    IconButton {
                        visible: root.canExpand
                        width: root.controlSize + 8
                        backgroundColor: root.chipColor
                        glyph: root.descriptionExpanded ? Lucide.chevronUp : Lucide.chevronDown
                        onClicked: root.descriptionExpanded = !root.descriptionExpanded
                    }

                    IconButton {
                        visible: root.showClose
                        glyph: Lucide.x
                        onClicked: root.closePopup()
                    }
                }
            }

            Item {
                width: parent.width
                height: root.descriptionExpanded ? messageText.implicitHeight + (imagePreview.visible ? root.contentSpacing + imagePreview.height : 0) : Math.max(messageText.implicitHeight, imagePreview.visible ? imagePreview.height : 0)

                Column {
                    id: messageText

                    width: Math.max(0, parent.width - (!root.descriptionExpanded && imagePreview.visible ? imagePreview.width + 8 : 0))
                    spacing: root.contentSpacing

                    StyledText {
                        id: summaryText

                        width: parent.width
                        visible: text.length > 0
                        text: root.notificationObject.summary || ""
                        font.pixelSize: root.summarySize
                        elide: root.descriptionExpanded ? Text.ElideNone : Text.ElideRight
                        maximumLineCount: root.descriptionExpanded ? -1 : 1
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    StyledText {
                        id: bodyText

                        width: parent.width
                        visible: text.length > 0
                        text: root.htmlBody
                        textFormat: Text.StyledText
                        role: "secondary"
                        font.pixelSize: root.bodySize
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        maximumLineCount: root.descriptionExpanded ? -1 : root.collapsedLines
                        elide: root.descriptionExpanded ? Text.ElideNone : Text.ElideRight
                        linkColor: Theme.primary
                        onLinkActivated: link => {
                            Qt.openUrlExternally(link);
                            if (!root.popup)
                                Settings.sidebarVisible = false;
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: mouse => {
                                if (bodyText.hoveredLink)
                                    mouse.accepted = false;
                            }
                            onClicked: {
                                if (root.canExpand)
                                    root.descriptionExpanded = !root.descriptionExpanded;
                            }
                        }
                    }
                }

                ClippingRectangle {
                    id: imagePreview

                    x: root.descriptionExpanded ? 0 : parent.width - width
                    y: root.descriptionExpanded ? messageText.implicitHeight + root.contentSpacing : 0
                    width: root.descriptionExpanded ? Math.min(parent.width, root.imageMaxHeight * contentImage.aspectRatio) : Math.min(root.thumbnailSize, root.thumbnailSize * contentImage.aspectRatio)
                    height: width / contentImage.aspectRatio
                    radius: root.cornerRadiusM
                    color: "transparent"
                    visible: root.contentImageSource !== "" && contentImage.implicitWidth > 0 && contentImage.status !== Image.Error

                    Image {
                        id: contentImage

                        readonly property real aspectRatio: implicitWidth > 0 && implicitHeight > 0 ? implicitWidth / implicitHeight : 1

                        anchors.fill: parent
                        source: root.contentImageSource
                        sourceSize: Qt.size(800, 800)
                        asynchronous: true
                        smooth: true
                        fillMode: Image.Stretch
                    }
                }
            }

            Item {
                width: parent.width
                height: actions.implicitHeight

                Flow {
                    id: actions

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: -root.actionPadding
                    spacing: 4

                    Repeater {
                        model: !root.showActions ? [] : (root.notificationObject.actions || []).filter(a => (a.text || "").trim() !== "")

                        TextButton {
                            required property var modelData
                            text: modelData.text
                            onClicked: root.invokeAction(modelData)
                        }
                    }

                    TextButton {
                        text: root.dismissText
                        onClicked: Notifications.discardNotification(root.notificationObject.notificationId)
                    }
                }
            }
        }

        // DMS timeoutBar: drains over the timer interval, stops while the timer is paused, refills on restart.
        Rectangle {
            id: timeoutBar

            readonly property bool active: root.popup && (root.timer?.interval ?? 0) > 0
            property real progress: 1

            // The timer can start before this card exists, so sync once the timer is known too.
            function sync() {
                if (active && root.timer.running) {
                    progress = 1;
                    progressAnim.restart();
                } else {
                    progressAnim.stop();
                }
            }

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: root.popupRadius
            anchors.bottomMargin: 4
            height: root.railHeight
            radius: height / 2
            visible: active && progress > 0
            color: Theme.secondaryContainer

            Rectangle {
                width: parent.width * timeoutBar.progress
                height: parent.height
                radius: height / 2
                color: Theme.primary
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: root.railHeight
                height: width
                radius: width / 2
                color: Theme.primary
            }

            NumberAnimation {
                id: progressAnim

                target: timeoutBar
                property: "progress"
                from: 1
                to: 0
                duration: root.timer?.interval ?? 0
                easing.type: Easing.Linear
            }

            Connections {
                target: timeoutBar.active ? root.timer : null
                function onRunningChanged() {
                    timeoutBar.sync();
                }
            }
        }
    }

    // DMS's BlurService border, drawn above the card content.
    Rectangle {
        visible: root.popup
        anchors.fill: cardSurface
        radius: cardSurface.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.popupBorder
    }

    // DankActionButton look: icon on a cornerRadius chip, primary state layer.
    component IconButton: Rectangle {
        id: iconButton

        property string glyph
        property color backgroundColor: "transparent"

        signal clicked

        width: root.controlSize
        height: root.controlSize
        radius: root.cornerRadiusM
        color: backgroundColor

        Icon {
            anchors.centerIn: parent
            text: iconButton.glyph
            size: Theme.iconSizeSmall
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.alpha(Theme.primary, iconMouse.pressed ? 0.12 : iconMouse.containsMouse ? 0.08 : 0)

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }

        MouseArea {
            id: iconMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: iconButton.clicked()
        }
    }

    // DankButton look with transparent background and primary text, as DMS uses for notification actions.
    component TextButton: Rectangle {
        id: textButton

        property string text

        signal clicked

        width: Math.min(actions.width, Math.max(label.implicitWidth + root.actionPadding * 2, 0))
        height: root.actionHeight
        radius: root.cornerRadiusM
        color: Theme.alpha(Theme.primary, textMouse.pressed ? 0.2 : textMouse.containsMouse ? 0.12 : 0)

        StyledText {
            id: label

            anchors.fill: parent
            anchors.leftMargin: root.actionPadding
            anchors.rightMargin: root.actionPadding
            horizontalAlignment: Text.AlignHCenter
            text: textButton.text
            font.pixelSize: Theme.fontSizeBase
            color: Theme.primary
            elide: Text.ElideRight
        }

        MouseArea {
            id: textMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: textButton.clicked()
        }

        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }
    }
}
