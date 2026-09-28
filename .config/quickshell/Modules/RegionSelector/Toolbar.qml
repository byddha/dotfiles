import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../../Components"
import "../../Config"
import "../../Services"

Rectangle {
    id: root

    required property int action
    required property bool adjusting
    property bool ocrMenuOpen: false
    property bool recordAudio: false
    property bool recordMic: false
    readonly property bool recordMode: action === RegionSelector.SnipAction.Record

    signal dismiss
    signal actionRequested(int newAction)
    signal fullscreenRequested
    signal cropRequested
    signal snipRequested(string mode, bool allLangs, bool translate)
    signal audioToggled
    signal micToggled

    property Item tipTarget: null
    property bool tipShown: false

    implicitWidth: content.implicitWidth + 14
    implicitHeight: content.implicitHeight + 14
    radius: Theme.radiusWindow
    color: Theme.surface
    border.width: 1
    border.color: Theme.popupBorder

    onAdjustingChanged: if (!adjusting)
        ocrMenuOpen = false

    RectangularShadow {
        z: -1
        anchors.fill: parent
        radius: root.radius
        blur: 8
        offset: Qt.vector2d(0, 4)
        color: Qt.rgba(0, 0, 0, 0.25)
    }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 2

        Rectangle {
            implicitWidth: modeRow.implicitWidth + 6
            implicitHeight: 40
            radius: 8
            color: Theme.colLayer2

            Row {
                id: modeRow
                anchors.centerIn: parent
                spacing: 2

                ToolButton {
                    implicitHeight: 34
                    radius: 5
                    icon: Lucide.camera
                    toggled: !root.recordMode
                    tip: "Screenshot"
                    keys: ["S"]
                    onClicked: root.actionRequested(RegionSelector.SnipAction.Copy)
                }
                ToolButton {
                    implicitHeight: 34
                    radius: 5
                    icon: Lucide.video
                    toggled: root.recordMode
                    tip: "Record"
                    keys: ["R"]
                    onClicked: root.actionRequested(RegionSelector.SnipAction.Record)
                }
            }
        }

        Separator {}

        ToolButton {
            icon: Lucide.monitor
            tip: "Full screen"
            keys: ["F"]
            detail: "…and open in editor"
            detailKeys: ["Shift", "F"]
            onClicked: root.fullscreenRequested()
        }
        ToolButton {
            icon: Lucide.crop
            active: root.adjusting
            tip: "Crop to content"
            keys: ["C"]
            onClicked: root.cropRequested()
        }

        Separator {}

        ToolButton {
            icon: Lucide.scanSearch
            active: root.adjusting
            tip: "Google Lens"
            keys: ["L"]
            onClicked: root.snipRequested("lens", false, false)
        }
        RowLayout {
            spacing: 1

            ToolButton {
                icon: Lucide.scanText
                active: root.adjusting
                rightFlat: true
                tip: "Copy text · English"
                keys: ["O"]
                onClicked: root.snipRequested("ocr", false, false)
            }
            ToolButton {
                id: ocrChevron
                implicitWidth: 18
                icon: Lucide.chevronUp
                iconSize: Theme.iconSizeSmall
                active: root.adjusting
                leftFlat: true
                toggled: root.ocrMenuOpen
                tip: "More text options"
                onClicked: root.ocrMenuOpen = !root.ocrMenuOpen
            }
        }

        Separator {}

        // Fixed width: the hint and the output buttons swap without resizing the bar
        Item {
            implicitWidth: Math.max(hint.implicitWidth + 16, output.implicitWidth)
            implicitHeight: 40

            StyledText {
                id: hint
                anchors.centerIn: parent
                visible: !root.adjusting
                role: "secondary"
                text: "Drag or click a window"
                font.pixelSize: Theme.fontSizeSmall
            }

            RowLayout {
                id: output
                anchors.centerIn: parent
                visible: root.adjusting
                spacing: 2

                ToolButton {
                    visible: !root.recordMode
                    icon: Lucide.pencil
                    tip: "Edit in Swappy"
                    keys: ["E"]
                    onClicked: root.snipRequested("edit", false, false)
                }
                ToolButton {
                    visible: !root.recordMode
                    icon: Lucide.save
                    tip: "Save to Pictures"
                    keys: ["Ctrl", "S"]
                    onClicked: root.snipRequested("save", false, false)
                }
                ToolButton {
                    visible: root.recordMode
                    icon: Lucide.volume2
                    toggled: root.recordAudio
                    tip: root.recordAudio ? "System audio · on" : "System audio · off"
                    keys: ["A"]
                    onClicked: root.audioToggled()
                }
                ToolButton {
                    visible: root.recordMode
                    icon: Lucide.mic
                    toggled: root.recordMic
                    tip: root.recordMic ? "Microphone · on" : "Microphone · off"
                    keys: ["M"]
                    onClicked: root.micToggled()
                }
                PrimaryButton {
                    Layout.leftMargin: 4
                    icon: root.recordMode ? Lucide.circleDot : Lucide.copy
                    text: root.recordMode ? "Record" : "Copy"
                    labels: ["Copy", "Record"]
                    tip: root.recordMode ? "Start recording" : "Copy to clipboard"
                    keys: ["Space", "Enter"]
                    onClicked: root.snipRequested("copy", false, false)
                }
            }
        }

        Separator {}

        ToolButton {
            icon: Lucide.x
            danger: true
            tip: "Cancel"
            keys: ["Esc"]
            onClicked: root.dismiss()
        }
    }

    // ---- OCR menu, opens upward from the split button
    Rectangle {
        id: ocrMenu
        visible: root.ocrMenuOpen
        x: {
            root.ocrMenuOpen;
            return Math.min(ocrChevron.parent.mapToItem(root, 0, 0).x, root.width - width);
        }
        y: -height - 6
        width: Math.max(ocrEnglish.implicitWidth, ocrAll.implicitWidth, ocrTranslate.implicitWidth) + 8
        height: menuColumn.implicitHeight + 8
        radius: Theme.radiusWindow
        color: Theme.surface
        border.width: 1
        border.color: Theme.popupBorder

        RectangularShadow {
            z: -1
            anchors.fill: parent
            radius: parent.radius
            blur: 8
            offset: Qt.vector2d(0, 4)
            color: Qt.rgba(0, 0, 0, 0.25)
        }

        Column {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 4

            MenuRow {
                id: ocrEnglish
                icon: Lucide.scanText
                text: "Copy text · English"
                keys: ["O"]
                onClicked: root.snipRequested("ocr", false, false)
            }
            MenuRow {
                id: ocrAll
                icon: Lucide.textSelect
                text: "Copy text · all languages"
                keys: ["Shift", "O"]
                onClicked: root.snipRequested("ocr", true, false)
            }
            MenuRow {
                id: ocrTranslate
                icon: Lucide.languages
                text: "Translate"
                keys: ["Ctrl", "O"]
                onClicked: root.snipRequested("ocr", true, true)
            }
        }
    }

    // ---- Tooltip, above the hovered button, kept inside the bar's width
    Timer {
        id: tipTimer
        interval: 400
        onTriggered: root.tipShown = true
    }
    onTipTargetChanged: {
        tipShown = false;
        if (tipTarget)
            tipTimer.restart();
        else
            tipTimer.stop();
    }

    Rectangle {
        id: tooltip
        readonly property Item target: root.tipTarget
        visible: root.tipShown && target !== null && !root.ocrMenuOpen
        x: target ? Math.max(0, Math.min(root.width - width, target.mapToItem(root, target.width / 2, 0).x - width / 2)) : 0
        y: -height - 8
        width: tipColumn.implicitWidth + 16
        height: tipColumn.implicitHeight + 12
        radius: Theme.radiusBase
        color: Theme.colLayer2
        border.width: 1
        border.color: Theme.popupBorder

        RectangularShadow {
            z: -1
            anchors.fill: parent
            radius: parent.radius
            blur: 8
            offset: Qt.vector2d(0, 4)
            color: Qt.rgba(0, 0, 0, 0.25)
        }

        Column {
            id: tipColumn
            anchors.centerIn: parent
            spacing: 4

            RowLayout {
                spacing: 8
                StyledText {
                    text: tooltip.target?.tip ?? ""
                    font.pixelSize: Theme.fontSizeTiny
                }
                Keycaps {
                    keys: tooltip.target?.keys ?? []
                }
            }
            RowLayout {
                readonly property string line: tooltip.target ? (tooltip.target.active ? tooltip.target.detail : "Select a region first") : ""
                visible: line !== ""
                spacing: 8
                StyledText {
                    role: "secondary"
                    text: parent.line
                    font.pixelSize: Theme.fontSizeTiny
                }
                Keycaps {
                    keys: tooltip.target?.active ? tooltip.target.detailKeys : []
                }
            }
        }
    }

    component Separator: Rectangle {
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        implicitWidth: 1
        implicitHeight: 24
        color: Theme.outlineVariant
    }

    component Keycaps: Row {
        property var keys: []
        property bool onPrimary: false
        visible: keys.length > 0
        spacing: 3

        Repeater {
            model: parent.keys
            Keycap {
                required property string modelData
                text: modelData
                onPrimary: parent.onPrimary
            }
        }
    }

    // Inactive buttons stay hoverable (the tooltip says why) and swallow clicks so a press
    // doesn't fall through and start a new selection, hence `active` instead of `enabled`.
    component ToolButton: Rectangle {
        id: button

        property string icon
        property int iconSize: Theme.iconSize
        property bool active: true
        property bool toggled: false
        property bool danger: false
        property bool leftFlat: false
        property bool rightFlat: false
        property string tip
        property var keys: []
        property string detail
        property var detailKeys: []

        signal clicked

        implicitWidth: 40
        implicitHeight: 40
        radius: Theme.radiusBase
        topLeftRadius: leftFlat ? 0 : radius
        bottomLeftRadius: leftFlat ? 0 : radius
        topRightRadius: rightFlat ? 0 : radius
        bottomRightRadius: rightFlat ? 0 : radius
        color: !active ? "transparent" : danger && mouse.containsMouse ? Theme.alpha(Theme.accentRed, mouse.pressed ? 0.24 : 0.16) : toggled ? Theme.alpha(Theme.primary, Theme.stateSelected) : "transparent"

        StateLayer {
            visible: button.active && !button.danger
            topLeftRadius: button.topLeftRadius
            bottomLeftRadius: button.bottomLeftRadius
            topRightRadius: button.topRightRadius
            bottomRightRadius: button.bottomRightRadius
            hovered: mouse.containsMouse
            pressed: mouse.pressed
        }

        Icon {
            anchors.centerIn: parent
            text: button.icon
            size: button.iconSize
            color: !button.active ? Theme.alpha(Theme.textSecondary, 0.35) : button.danger && mouse.containsMouse ? Theme.accentRed : button.toggled ? Theme.primary : mouse.containsMouse ? Theme.textColor : Theme.textSecondary
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: button.active ? Qt.PointingHandCursor : Qt.ArrowCursor
            onContainsMouseChanged: {
                if (containsMouse)
                    root.tipTarget = button;
                else if (root.tipTarget === button)
                    root.tipTarget = null;
            }
            onClicked: if (button.active)
                button.clicked()
        }
    }

    // [icon] [label] [↵]: icon and keycap sit at fixed spots, the label is centered between them. The width
    // comes from the longest of `labels`, so swapping Copy / Record never moves anything.
    component PrimaryButton: Rectangle {
        id: primary

        property string icon
        property string text
        property var labels: []
        property string tip
        property var keys: []
        readonly property bool active: true
        readonly property string detail: ""
        readonly property var detailKeys: []
        readonly property int padLeft: 10
        readonly property int padRight: 8
        readonly property int iconBox: 20
        readonly property int gap: 8

        signal clicked

        implicitWidth: padLeft + iconBox + gap + widestLabel.implicitWidth + gap + keycap.implicitWidth + padRight
        implicitHeight: 40
        radius: Theme.radiusBase
        color: Theme.primary

        // Measures the longest label; never shown
        Column {
            id: widestLabel
            visible: false
            Repeater {
                model: primary.labels
                StyledText {
                    required property string modelData
                    text: modelData
                    font: primaryLabel.font
                }
            }
        }

        StateLayer {
            primaryFill: true
            hovered: primaryMouse.containsMouse
            pressed: primaryMouse.pressed
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: primary.padLeft
            anchors.rightMargin: primary.padRight
            spacing: primary.gap

            Icon {
                Layout.preferredWidth: primary.iconBox
                text: primary.icon
                color: Theme.primaryText
            }
            StyledText {
                id: primaryLabel
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: primary.text
                font.pixelSize: Theme.fontSizeBase
                font.weight: Font.DemiBold
                color: Theme.primaryText
            }
            Keycaps {
                id: keycap
                keys: ["Enter"]
                onPrimary: true
            }
        }

        MouseArea {
            id: primaryMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: {
                if (containsMouse)
                    root.tipTarget = primary;
                else if (root.tipTarget === primary)
                    root.tipTarget = null;
            }
            onClicked: primary.clicked()
        }
    }

    component MenuRow: Rectangle {
        id: row

        property string icon
        property string text
        property var keys: []

        signal clicked

        width: parent.width
        implicitWidth: rowContent.implicitWidth + 20
        height: 32
        radius: Theme.radiusBase
        color: "transparent"

        StateLayer {
            hovered: rowMouse.containsMouse
            pressed: rowMouse.pressed
        }

        RowLayout {
            id: rowContent
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Icon {
                text: row.icon
                color: Theme.textSecondary
            }
            StyledText {
                Layout.fillWidth: true
                Layout.rightMargin: 14
                text: row.text
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Normal
            }
            Keycaps {
                keys: row.keys
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }
}
