import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Config"
import "../../Services"
import "../../Components"

/**
 * LockView - What the lock and the greeter show on one monitor: its wallpaper, and on the primary
 * monitor the clock, the password field, the battery and the power menu.
 *
 * The typed text lives in `input`, one for all monitors: Hyprland gives the keyboard to the monitor
 * under the pointer, so a secondary monitor takes the keys too and feeds the same field.
 *
 * The auth behind the field is any object with: busy, message, error, failed() and submit(password).
 * The lock gives PAM, the greeter greetd, the preview a fake one. The greeter's also has the user,
 * the session, and greetd's own questions (prompt, echo, cancel()).
 */
Item {
    id: root

    required property ShellScreen screen
    required property QtObject auth
    // A LockInput
    required property QtObject input
    // False while the monitors are off: the wallpaper's video stops decoding
    property bool playing: true
    // "lock" or "greeter": the power menu of the greeter has no Log out
    property string context: "lock"
    readonly property bool greeter: context === "greeter"
    // The greeter's Sessions
    property QtObject sessions: null
    readonly property bool primary: LockConfig.isPrimary(screen)

    LockWallpaper {
        anchors.fill: parent
        screen: root.screen
        playing: root.playing
    }

    // Dimmed, so the text stays readable over any wallpaper, a moving one too
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    Loader {
        anchors.fill: parent
        active: root.primary
        sourceComponent: formComponent
    }

    // A secondary monitor shows no field, but typing there still fills the one on the primary
    Loader {
        active: !root.primary
        sourceComponent: Item {
            focus: true
            Component.onCompleted: forceActiveFocus()

            Keys.onPressed: event => {
                event.accepted = true;
                if (root.auth.busy)
                    return;
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (root.input.text !== "")
                        root.auth.submit(root.input.text);
                } else if (event.key === Qt.Key_Escape) {
                    root.input.text = "";
                } else if (event.key === Qt.Key_Backspace) {
                    root.input.text = root.input.text.slice(0, -1);
                } else if (event.text.length === 1 && event.text >= " ") {
                    root.input.text += event.text;
                }
            }
        }
    }

    Component {
        id: formComponent

        Item {
            id: form

            // "power", "session" or ""
            property string openMenu: ""
            readonly property string prompt: root.greeter ? root.auth.prompt : ""

            onOpenMenuChanged: {
                if (openMenu === "") {
                    menu.shutdownArmed = false;
                    field.forceActiveFocus();
                }
            }

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            CapsLock {
                id: capsLock
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                // Two thirds down: the middle of a wallpaper is usually its subject
                y: parent.height * 2 / 3 - height / 2
                spacing: Theme.spacingLarge

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatTime(clock.date, "hh:mm")
                    font.pixelSize: 96
                    font.weight: Font.Light
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: -Theme.spacingLarge
                    role: "secondary"
                    text: Qt.formatDate(clock.date, "dddd d MMMM")
                    font.pixelSize: Theme.fontSizeLarge
                }

                // The user to log in, edited after a click
                TextInput {
                    id: userField

                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Theme.spacingBase
                    Layout.bottomMargin: -Theme.spacingBase
                    // Not 0 wide when empty, or a click on the placeholder reaches nothing
                    Layout.preferredWidth: Math.max(implicitWidth, 120)
                    visible: root.greeter
                    text: root.greeter ? root.auth.user : ""
                    readOnly: root.auth.busy || form.prompt !== ""
                    color: Theme.textColor
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    horizontalAlignment: TextInput.AlignHCenter
                    selectByMouse: true
                    cursorDelegate: Rectangle {
                        width: 1
                        color: Theme.textColor
                        // Hidden while empty: centered, it would cut through the placeholder
                        visible: userField.text !== "" && userField.cursorVisible
                    }

                    onTextEdited: root.auth.user = text
                    onAccepted: field.forceActiveFocus()
                    Keys.onTabPressed: field.forceActiveFocus()
                    Keys.onEscapePressed: field.forceActiveFocus()

                    // Edited in place, so it still reads as a name: only an underline while editing
                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: 1
                        color: Theme.primary
                        visible: userField.activeFocus
                    }

                    StyledText {
                        anchors.centerIn: parent
                        visible: userField.text === ""
                        role: "tertiary"
                        text: "User"
                        font.pixelSize: Theme.fontSizeLarge
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Theme.spacingLarge
                    transform: Translate {
                        id: shake
                    }
                    implicitWidth: 320
                    implicitHeight: 44
                    radius: Theme.radiusWindow
                    color: Theme.alpha(Theme.hostSurface, 0.85)
                    border.width: 1
                    border.color: root.auth.error && messageTimer.running ? Theme.accentRed : field.activeFocus ? Theme.primary : Theme.popupBorder

                    TextInput {
                        id: field

                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingLarge
                        anchors.rightMargin: Theme.spacingLarge
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        echoMode: form.prompt !== "" && root.auth.echo ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        color: Theme.textColor
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.fontSizeLarge
                        // Typing while the password is checked would be lost or sent twice
                        readOnly: root.auth.busy
                        focus: true
                        // Hidden while empty: centered, it would cut through the placeholder
                        cursorDelegate: Rectangle {
                            width: 1
                            color: Theme.textColor
                            visible: field.text !== "" && field.cursorVisible
                        }

                        onTextEdited: root.input.text = text
                        onAccepted: {
                            if (text !== "")
                                root.auth.submit(text);
                        }
                        Keys.onEscapePressed: {
                            if (form.openMenu !== "")
                                form.openMenu = "";
                            else if (form.prompt !== "")
                                root.auth.cancel();
                            else
                                root.input.text = "";
                        }
                        Keys.onBacktabPressed: {
                            if (root.greeter)
                                userField.forceActiveFocus();
                        }

                        StyledText {
                            anchors.centerIn: parent
                            visible: field.text === ""
                            role: "tertiary"
                            text: form.prompt || "Password"
                            font.pixelSize: Theme.fontSizeLarge
                        }
                    }
                }

                StyledText {
                    readonly property bool showMessage: messageTimer.running && root.auth.message !== ""

                    Layout.alignment: Qt.AlignHCenter
                    // Kept in the layout when empty, so the field does not move when a message comes
                    opacity: root.auth.busy || showMessage || capsLock.on ? 1 : 0
                    color: showMessage && root.auth.error ? Theme.accentRed : !root.auth.busy && !showMessage ? Theme.accentOrange : Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity)
                    // A message from the check itself (e.g. a lockout notice) wins over "Checking…"
                    // Caps Lock stays told beside a message: a wrong password is when it matters most
                    text: (showMessage ? root.auth.message : root.auth.busy ? "Checking…" : "") + (capsLock.on ? (showMessage || root.auth.busy ? " · " : "") + "Caps Lock is on" : "") || " "
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            Row {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Theme.spacingLarge * 2
                visible: Battery.available
                spacing: Theme.spacingSmall

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Battery.icon
                    color: Battery.charging ? Theme.accentGreen : Battery.isCritical ? Theme.accentRed : Battery.isLow ? Theme.accentOrange : Theme.textColor
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${Battery.percentage}%`
                }
            }

            // Closes the menu on a click anywhere else
            MouseArea {
                anchors.fill: parent
                enabled: form.openMenu !== ""
                onClicked: form.openMenu = ""
            }

            Rectangle {
                anchors.right: powerButton.right
                anchors.bottom: powerButton.top
                anchors.bottomMargin: Theme.spacingBase
                visible: form.openMenu === "power"
                width: 232
                height: menu.implicitHeight + 12
                radius: Theme.radiusWindow
                color: Theme.hostSurface
                border.width: 1
                border.color: Theme.popupBorder

                PowerMenuList {
                    id: menu

                    anchors.fill: parent
                    anchors.margins: 6
                    context: root.context
                    onChosen: form.openMenu = ""
                }
            }

            IconButton {
                id: powerButton

                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Theme.spacingLarge * 2
                implicitWidth: 40
                implicitHeight: 40
                icon: Lucide.power
                iconSize: Theme.iconSizeLarge
                toggled: form.openMenu === "power"
                onClicked: form.openMenu = form.openMenu === "power" ? "" : "power"
            }

            Rectangle {
                anchors.right: sessionButton.right
                anchors.bottom: sessionButton.top
                anchors.bottomMargin: Theme.spacingBase
                visible: form.openMenu === "session"
                width: 232
                height: sessionList.implicitHeight + 12
                radius: Theme.radiusWindow
                color: Theme.hostSurface
                border.width: 1
                border.color: Theme.popupBorder

                ColumnLayout {
                    id: sessionList

                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 1

                    Repeater {
                        model: root.sessions?.list ?? []

                        MenuRow {
                            required property var modelData

                            label: modelData.name
                            selected: modelData.id === root.auth.session?.id
                            onActivated: {
                                root.auth.session = modelData;
                                form.openMenu = "";
                            }
                        }
                    }
                }
            }

            // The session to start, beside the power button
            Rectangle {
                id: sessionButton

                anchors.right: powerButton.left
                anchors.rightMargin: Theme.spacingBase
                anchors.verticalCenter: powerButton.verticalCenter
                // Not before the sessions are read: it would say "No session" for a moment
                visible: root.greeter && root.auth.session !== null
                implicitWidth: sessionRow.implicitWidth + Theme.spacingLarge * 2
                implicitHeight: 40
                radius: Theme.radiusBase
                color: form.openMenu === "session" ? Theme.alpha(Theme.primary, Theme.stateSelected) : "transparent"

                StateLayer {
                    hovered: sessionArea.containsMouse
                    pressed: sessionArea.pressed
                }

                Row {
                    id: sessionRow

                    anchors.centerIn: parent
                    spacing: Theme.spacingBase

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Lucide.monitor
                        color: Theme.textSecondary
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.auth.session?.name ?? ""
                    }
                }

                MouseArea {
                    id: sessionArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: form.openMenu = form.openMenu === "session" ? "" : "session"
                }
            }

            SequentialAnimation {
                id: shakeAnimation

                NumberAnimation {
                    target: shake
                    property: "x"
                    to: -10
                    duration: 40
                }
                NumberAnimation {
                    target: shake
                    property: "x"
                    to: 10
                    duration: 70
                }
                NumberAnimation {
                    target: shake
                    property: "x"
                    to: -6
                    duration: 60
                }
                NumberAnimation {
                    target: shake
                    property: "x"
                    to: 6
                    duration: 60
                }
                NumberAnimation {
                    target: shake
                    property: "x"
                    to: 0
                    duration: 50
                }
            }

            // A message stays a few seconds, then the line is empty again
            Timer {
                id: messageTimer
                interval: 4000
            }

            Connections {
                target: root.auth
                // promptChanged is the greeter's only
                ignoreUnknownSignals: true

                function onMessageChanged() {
                    if (root.auth.message !== "")
                        messageTimer.restart();
                }

                function onFailed() {
                    root.input.text = "";
                    shakeAnimation.restart();
                }

                // A new question gets an empty field: the password typed before must not show in it
                function onPromptChanged() {
                    root.input.text = "";
                }
            }

            // Text typed on a secondary monitor
            Connections {
                target: root.input

                function onTextChanged() {
                    if (field.text !== root.input.text)
                        field.text = root.input.text;
                }
            }

            Component.onCompleted: field.forceActiveFocus()
        }
    }
}
