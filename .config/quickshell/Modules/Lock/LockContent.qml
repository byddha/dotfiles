import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../Components"
import "../../Config"
import "../../Services"
import "../Sidebar"
import "../Bar"

FocusScope {
    id: root

    focus: true

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: "file:///home/bida/.config/hypr/assets/wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        cache: true
        visible: false
        layer.enabled: true
    }

    ShaderEffect {
        anchors.fill: parent
        property var source: wallpaper
        property color darkColor: Theme.colLayer0
        property color lightColor: Theme.primary
        property real gamma: 1.4
        property real grainStrength: 0.04
        property real vignetteStrength: 0.55
        property real halftoneEdge: 0.55
        property real halftoneCellSize: 8.0
        property real halftoneStrength: 1.0
        property vector2d resolution: Qt.vector2d(width, height)
        vertexShader: "shaders/lockbg.vert.qsb"
        fragmentShader: "shaders/lockbg.frag.qsb"
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.colLayer0
        opacity: 0.15
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0.0
                color: Qt.rgba(0, 0, 0, 0.5)
            }
            GradientStop {
                position: 0.4
                color: Qt.rgba(0, 0, 0, 0.0)
            }
            GradientStop {
                position: 0.6
                color: Qt.rgba(0, 0, 0, 0.0)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(0, 0, 0, 0.55)
            }
        }
    }

    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Theme.spacingLarge * 2
        spacing: Theme.spacingBase
        opacity: 0.92

        BatteryButton {}

        StyledText {
            id: uptimeText
            color: "white"
            opacity: 0.85
            font.pixelSize: Theme.fontSizeSmall
            text: ""

            property real bootSeconds: 0

            function format(secsSinceBoot) {
                const total = Math.floor(secsSinceBoot);
                const d = Math.floor(total / 86400);
                const h = Math.floor((total % 86400) / 3600);
                const m = Math.floor((total % 3600) / 60);
                let parts = [];
                if (d > 0)
                    parts.push(d + "d");
                if (h > 0 || d > 0)
                    parts.push(h + "h");
                parts.push(m + "m");
                return "Up " + parts.join(" ");
            }

            Process {
                id: uptimeProc
                command: ["cat", "/proc/uptime"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        const secs = parseFloat(text.split(" ")[0]);
                        if (!isNaN(secs)) {
                            uptimeText.bootSeconds = secs;
                            uptimeText.text = uptimeText.format(secs);
                        }
                    }
                }
            }

            Timer {
                interval: 60000
                running: true
                repeat: true
                onTriggered: uptimeProc.running = true
            }
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: Theme.spacingLarge * 2
        spacing: Theme.spacingBase
        opacity: 0.92

        PowerActionButton {
            icon: Icons.shutdown
            onClicked: PowerActions.poweroff()
        }
        PowerActionButton {
            icon: Icons.reboot
            onClicked: PowerActions.reboot()
        }
        PowerActionButton {
            icon: Icons.logout
            onClicked: PowerActions.logout()
        }
        PowerActionButton {
            icon: Icons.suspend
            onClicked: PowerActions.suspend()
        }
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.spacingLarge * 2
        width: 380
        spacing: Theme.spacingLarge

        WeatherCard {
            Layout.fillWidth: true
            opacity: 0.92
        }

        QuickSliders {
            Layout.fillWidth: true
            opacity: 0.92
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacingLarge

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: -8

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: clock.date.toLocaleTimeString(Qt.locale(), "HH:mm")
                font.pixelSize: 96
                font.weight: Font.Light
                color: "white"
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: clock.date.toLocaleDateString(Qt.locale(), Locale.LongFormat)
                font.pixelSize: Theme.fontSizeBase
                color: "white"
                opacity: 0.8
            }
        }

        Item {
            id: passwordBox
            property bool revealed: false

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 360
            Layout.preferredHeight: 48
            Layout.topMargin: -Theme.spacingBase

            TextInput {
                id: passwordField
                anchors.left: parent.left
                anchors.right: revealBtn.left
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                anchors.leftMargin: Theme.spacingBase
                anchors.rightMargin: Theme.spacingBase
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                color: passwordBox.revealed ? "white" : "transparent"
                cursorVisible: passwordBox.revealed
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBase
                echoMode: passwordBox.revealed ? TextInput.Normal : TextInput.Password
                passwordCharacter: "•"
                enabled: !SessionLock.authenticating
                focus: true
                text: SessionLock.password
                onTextChanged: {
                    if (SessionLock.password !== text)
                        SessionLock.password = text;
                    ekg.spike(0.85 + Math.random() * 0.3);
                }
                Connections {
                    target: SessionLock
                    function onPasswordChanged() {
                        if (passwordField.text !== SessionLock.password)
                            passwordField.text = SessionLock.password;
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        SessionLock.tryUnlock();
                        event.accepted = true;
                    }
                }

                Component.onCompleted: forceActiveFocus()
            }

            Canvas {
                id: ekg
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - (revealBtn.width + Theme.spacingBase) * 2
                antialiasing: true
                visible: !passwordBox.revealed

                property var pulses: []
                property real timeNow: 0
                readonly property real lifetimeMs: 2200
                readonly property real pixelsPerSec: 140

                function spike(strength) {
                    pulses.push({
                        t: timeNow,
                        s: strength
                    });
                    if (pulses.length > 32)
                        pulses.shift();
                    requestPaint();
                }

                Timer {
                    interval: 33
                    running: true
                    repeat: true
                    onTriggered: {
                        ekg.timeNow += 33;
                        ekg.requestPaint();
                    }
                }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width;
                    const h = height;
                    const baseY = h / 2;

                    // baseline
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.15);
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(0, baseY);
                    ctx.lineTo(w, baseY);
                    ctx.stroke();

                    // active EKG line
                    const focused = passwordField.activeFocus;
                    ctx.strokeStyle = focused ? Theme.primary : Qt.rgba(1, 1, 1, 0.5);
                    ctx.lineWidth = focused ? 2 : 1.5;
                    ctx.lineJoin = "round";
                    ctx.lineCap = "round";

                    ctx.beginPath();
                    ctx.moveTo(0, baseY);

                    // sample line with spikes
                    const step = 2;
                    for (let x = 0; x <= w; x += step) {
                        let y = baseY;
                        for (let i = 0; i < pulses.length; i++) {
                            const p = pulses[i];
                            const age = timeNow - p.t;
                            if (age > lifetimeMs)
                                continue;
                            // spike position: starts at right, scrolls left
                            const spikeX = w - (age / 1000) * pixelsPerSec;
                            if (spikeX < -40 || spikeX > w + 40)
                                continue;
                            const dx = x - spikeX;
                            // P-Q-R-S-T-like waveform
                            const fade = 1 - age / lifetimeMs;
                            const amp = (h * 0.42) * fade * p.s;
                            // small p-wave bump
                            y -= amp * 0.15 * Math.exp(-Math.pow(dx + 9, 2) / 6);
                            // q dip
                            y += amp * 0.18 * Math.exp(-Math.pow(dx + 3, 2) / 2);
                            // R spike up (sharp)
                            y -= amp * 1.0 * Math.exp(-Math.pow(dx, 2) / 1.5);
                            // S dip down
                            y += amp * 0.45 * Math.exp(-Math.pow(dx - 3, 2) / 2);
                            // T wave bump
                            y -= amp * 0.22 * Math.exp(-Math.pow(dx - 9, 2) / 8);
                        }
                        ctx.lineTo(x, y);
                    }
                    ctx.stroke();
                }
            }

            Item {
                id: revealBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Theme.spacingBase
                width: 36
                height: 36

                StyledText {
                    anchors.centerIn: parent
                    text: passwordBox.revealed ? "󰈉" : "󰈈"
                    color: "white"
                    font.pixelSize: 18
                    opacity: revealMouse.pressed ? 0.6 : (passwordField.text.length > 0 ? 0.9 : 0.4)
                }

                MouseArea {
                    id: revealMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: passwordBox.revealed = !passwordBox.revealed
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: Theme.fontSizeBase + 4
            text: SessionLock.authenticating ? "Authenticating..." : (SessionLock.errorMessage || "")
            font.pixelSize: Theme.fontSizeSmall
            color: SessionLock.errorMessage ? Theme.accentRed : "white"
            opacity: 0.9
        }

        Item {
            id: mediaWrap
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 420
            Layout.preferredHeight: 120
            Layout.topMargin: Theme.spacingLarge
            visible: MprisController.activePlayer !== null
            opacity: 0.92

            property list<real> visualizerValues: []

            Process {
                running: mediaWrap.visible
                command: ["cava", "-p", Qt.resolvedUrl("../../scripts/cava_config.txt").toString().replace("file://", "")]
                stdout: SplitParser {
                    onRead: data => {
                        mediaWrap.visualizerValues = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                    }
                }
            }

            MediaCard {
                id: tintedMedia
                anchors.fill: parent
                showControls: true
                showVisualizer: true
                visualizerValues: mediaWrap.visualizerValues
                compact: false
                layer.enabled: true
                layer.effect: ShaderEffect {
                    property color darkColor: Theme.colLayer0
                    property color lightColor: Theme.primary
                    property real gamma: 1.4
                    property real grainStrength: 0.0
                    property real vignetteStrength: 0.0
                    property real halftoneEdge: 0.0
                    property real halftoneCellSize: 1.0
                    property real halftoneStrength: 0.0
                    property vector2d resolution: Qt.vector2d(tintedMedia.width, tintedMedia.height)
                    vertexShader: "shaders/lockbg.vert.qsb"
                    fragmentShader: "shaders/lockbg.frag.qsb"
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: {
            if (!passwordField.activeFocus)
                passwordField.forceActiveFocus();
        }
    }

    Component.onCompleted: passwordField.forceActiveFocus()
}
