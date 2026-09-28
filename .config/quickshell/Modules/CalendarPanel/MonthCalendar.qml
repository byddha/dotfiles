pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Services"
import "../../Components"

// The month grid with day markers. The line under it names the hovered day (today when none is),
// and a right click on a day turns it into the input for that day's personal event.
Card {
    id: root

    property var today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()
    readonly property bool onTodaysMonth: year === today.getFullYear() && month === today.getMonth()
    property var hoveredDay: null
    property var editedDay: null

    readonly property var kindNames: ({
            "user": "personal event",
            "public": "public holiday",
            "nameday": "name day",
            "observance": "observance"
        })

    // Always six weeks, Monday first, so the card never changes height between months
    readonly property var days: {
        const lead = (new Date(year, month, 1).getDay() + 6) % 7;
        const cells = [];
        for (let i = 0; i < 42; i++) {
            const date = new Date(year, month, 1 - lead + i);
            const y = date.getFullYear();
            const m = date.getMonth();
            const d = date.getDate();
            cells.push({
                "year": y,
                "month": m,
                "day": d,
                "inMonth": m === month,
                "today": y === today.getFullYear() && m === today.getMonth() && d === today.getDate(),
                "event": HolidayService.getHoliday(y, m, d)
            });
        }
        return cells;
    }
    readonly property var shownDay: hoveredDay ?? {
        "year": today.getFullYear(),
        "month": today.getMonth(),
        "day": today.getDate(),
        "inMonth": true,
        "today": true,
        "event": HolidayService.getHoliday(today.getFullYear(), today.getMonth(), today.getDate())
    }

    function showMonth(offset) {
        const date = new Date(year, month + offset, 1);
        year = date.getFullYear();
        month = date.getMonth();
    }

    function showToday() {
        year = today.getFullYear();
        month = today.getMonth();
    }

    function sameDay(a, b) {
        return !!a && !!b && a.year === b.year && a.month === b.month && a.day === b.day;
    }

    function dateOf(day) {
        return new Date(day.year, day.month, day.day);
    }

    function editDay(day) {
        editedDay = day;
        eventField.text = UserEventsService.getEvent(day.year, day.month, day.day) || "";
        eventField.forceActiveFocus();
    }

    // Focus goes back to the card, so the next Esc reaches the popout and closes it
    function closeEdit() {
        editedDay = null;
        eventField.text = "";
        root.forceActiveFocus();
    }

    function saveEdit() {
        const text = eventField.text.trim();
        if (text)
            UserEventsService.setEvent(editedDay.year, editedDay.month, editedDay.day, text);
        else
            UserEventsService.deleteEvent(editedDay.year, editedDay.month, editedDay.day);
        closeEdit();
    }

    padding: Theme.spacingLarge

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date();
            if (now.getDate() !== root.today.getDate())
                root.today = now;
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacingSmall

        Row {
            Layout.fillWidth: true

            StyledText {
                text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM")
                font.pixelSize: Theme.fontSizeLarge
            }
            StyledText {
                role: "secondary"
                text: ` ${root.year}`
                font.pixelSize: Theme.fontSizeLarge
            }
        }

        NavButton {
            icon: Lucide.chevronLeft
            onClicked: root.showMonth(-1)
        }

        Rectangle {
            implicitWidth: todayLabel.implicitWidth + 20
            implicitHeight: 28
            radius: Theme.radiusBase
            color: root.onTodaysMonth ? "transparent" : todayArea.containsMouse ? Theme.colLayer3 : Theme.colLayer2

            StyledText {
                id: todayLabel

                anchors.centerIn: parent
                role: root.onTodaysMonth ? "tertiary" : "primary"
                text: "Today"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            MouseArea {
                id: todayArea

                anchors.fill: parent
                enabled: !root.onTodaysMonth
                hoverEnabled: true
                onClicked: root.showToday()
            }
        }

        NavButton {
            icon: Lucide.chevronRight
            onClicked: root.showMonth(1)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacingLarge
        spacing: 0

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            StyledText {
                required property string modelData

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                horizontalAlignment: Text.AlignHCenter
                role: "tertiary"
                text: modelData
                font.pixelSize: Theme.fontSizeTiny
                font.weight: Font.Medium
            }
        }
    }

    // Rows grow past 40 px to fill the height the weather card gives the card
    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: Theme.spacingSmall
        columns: 7
        columnSpacing: 0
        rowSpacing: 0

        Repeater {
            model: root.days

            DayCell {}
        }
    }

    // Always as tall as two lines of a long name, so hovering never moves anything
    Item {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacingBase
        implicitHeight: 44

        Rectangle {
            anchors.fill: parent
            visible: root.editedDay === null
            radius: Theme.radiusBase
            color: Theme.colLayer2

            RowLayout {
                id: dayLine

                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                Marker {
                    id: lineMarker

                    visible: type !== ""
                    type: root.shownDay.event?.type ?? ""
                }
                StyledText {
                    id: dayName

                    // What the rest of the line leaves. A layout item without fillWidth keeps exactly its
                    // preferred width, so this is what a long name (a name day lists all its names) gets.
                    readonly property real room: dayLine.width - (lineMarker.visible ? lineMarker.implicitWidth + dayLine.spacing : 0) - kind.implicitWidth - lineEnd.implicitWidth - dayLine.spacing * 3
                    readonly property bool wraps: oneLine.width > room

                    text: root.shownDay.event?.name ?? (root.shownDay.today ? "Today" : Qt.formatDate(root.dateOf(root.shownDay), "ddd d MMM"))
                    font.pixelSize: wraps ? Theme.fontSizeTiny : Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    Layout.preferredWidth: Math.min(implicitWidth, room)

                    TextMetrics {
                        id: oneLine

                        font.family: Theme.fontUi
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        text: dayName.text
                    }
                }
                StyledText {
                    id: kind

                    role: "tertiary"
                    text: `· ${root.shownDay.event ? root.kindNames[root.shownDay.event.type] : "no events"}`
                    font.pixelSize: Theme.fontSizeSmall
                }
                Item {
                    Layout.fillWidth: true
                }
                StyledText {
                    id: lineEnd

                    role: "tertiary"
                    text: root.shownDay.event ? (root.shownDay.today ? "Today" : Qt.formatDate(root.dateOf(root.shownDay), "ddd d MMM")) : root.shownDay.today ? "Right-click a day to add" : "Right-click to add"
                    font.pixelSize: Theme.fontSizeTiny
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            visible: root.editedDay !== null
            spacing: Theme.spacingBase

            StyledText {
                Layout.preferredWidth: 52
                role: "secondary"
                text: root.editedDay ? Qt.formatDate(root.dateOf(root.editedDay), "d MMM") : ""
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: Theme.radiusBase
                color: Theme.colLayer2
                border.width: 1
                border.color: Theme.primary

                TextInput {
                    id: eventField

                    anchors.left: parent.left
                    anchors.right: keys.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10
                    anchors.rightMargin: Theme.spacingBase
                    clip: true
                    color: Theme.textColor
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.primaryText
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.fontSizeSmall
                    onAccepted: root.saveEdit()
                    Keys.onEscapePressed: event => {
                        event.accepted = true;
                        root.closeEdit();
                    }

                    StyledText {
                        anchors.fill: parent
                        visible: eventField.text === ""
                        role: "tertiary"
                        text: "Add an event…"
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                Row {
                    id: keys

                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingSmall

                    Keycap {
                        text: "Enter"
                    }
                    Keycap {
                        text: "Esc"
                    }
                }
            }

            ActionButton {
                icon: Lucide.check
                fill: Theme.primary
                glyph: Theme.primaryText
                onClicked: root.saveEdit()
            }
            ActionButton {
                icon: Lucide.x
                fill: Theme.colLayer2
                glyph: Theme.textColor
                onClicked: root.closeEdit()
            }
        }
    }

    component DayCell: Item {
        id: cell

        required property var modelData

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 1
        implicitHeight: 40

        Rectangle {
            id: plate

            anchors.horizontalCenter: parent.horizontalCenter
            // The plate and the marker under it, centred in the cell
            y: Math.round((parent.height - 34) / 2)
            width: 30
            height: 26
            radius: Theme.radiusBase
            color: cell.modelData.today ? Theme.primary : area.containsMouse ? Theme.colLayer2 : "transparent"
            border.width: root.sameDay(root.editedDay, cell.modelData) ? 1 : 0
            border.color: Theme.outline

            StyledText {
                anchors.centerIn: parent
                role: cell.modelData.inMonth ? "primary" : "tertiary"
                color: cell.modelData.today ? Theme.primaryText : cell.modelData.inMonth ? Theme.textColor : Theme.alpha(Theme.textSecondary, Theme.tertiaryOpacity)
                text: cell.modelData.day
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        Marker {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: plate.bottom
            anchors.topMargin: 3
            type: cell.modelData.inMonth ? cell.modelData.event?.type ?? "" : ""
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onContainsMouseChanged: {
                if (containsMouse)
                    root.hoveredDay = cell.modelData;
                else if (root.sameDay(root.hoveredDay, cell.modelData))
                    root.hoveredDay = null;
            }
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.editDay(cell.modelData);
            }
        }
    }

    // A dot for a personal event, a diamond for a public holiday, a cross for a name day, an asterisk
    // for an observance
    component Marker: Item {
        id: marker

        property string type

        implicitWidth: 8
        implicitHeight: 8

        Rectangle {
            anchors.centerIn: parent
            visible: marker.type === "user" || marker.type === "public"
            width: 5
            height: 5
            radius: marker.type === "user" ? 2.5 : 0
            rotation: marker.type === "public" ? 45 : 0
            color: marker.type === "public" ? Theme.accentRed : Theme.primary
        }

        Item {
            anchors.centerIn: parent
            visible: marker.type === "nameday"
            width: 7
            height: 7

            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: 1.5
                color: Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity)
            }
            Rectangle {
                anchors.centerIn: parent
                width: 1.5
                height: 7
                color: Theme.alpha(Theme.textSecondary, Theme.secondaryOpacity)
            }
        }

        Icon {
            anchors.centerIn: parent
            visible: marker.type === "observance"
            size: 8
            text: Lucide.asterisk
            color: Theme.alpha(Theme.textSecondary, Theme.tertiaryOpacity)
        }
    }

    component NavButton: Rectangle {
        id: navButton

        property string icon

        signal clicked

        implicitWidth: 28
        implicitHeight: 28
        radius: Theme.radiusBase
        color: navArea.containsMouse ? Theme.colLayer3 : Theme.colLayer2

        Icon {
            anchors.centerIn: parent
            text: navButton.icon
        }

        MouseArea {
            id: navArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: navButton.clicked()
        }
    }

    component ActionButton: Rectangle {
        id: actionButton

        property string icon
        property color fill
        property color glyph

        signal clicked

        implicitWidth: 32
        implicitHeight: 32
        radius: Theme.radiusBase
        color: actionArea.containsMouse ? Qt.lighter(fill, 1.15) : fill

        Icon {
            anchors.centerIn: parent
            text: actionButton.icon
            color: actionButton.glyph
        }

        MouseArea {
            id: actionArea

            anchors.fill: parent
            hoverEnabled: true
            onClicked: actionButton.clicked()
        }
    }
}
