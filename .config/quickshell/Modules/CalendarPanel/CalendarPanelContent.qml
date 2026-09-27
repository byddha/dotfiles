import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Services"
import "../../Components"

Item {
    id: root

    property var now: new Date()

    implicitWidth: 380
    implicitHeight: content.implicitHeight

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: Theme.spacingBase

        Rectangle {
            id: banner
            Layout.fillWidth: true
            Layout.preferredHeight: 72 + Theme.spacingBase * 2  // Fixed height to prevent jank
            radius: Theme.radiusBase
            color: Theme.primary

            Item {
                id: bannerContent
                anchors.fill: parent
                anchors.margins: Theme.spacingBase

                // Date info - anchored to left
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    // Day number + Month
                    Row {
                        spacing: Theme.spacingBase

                        // Day number (large, only show for current month)
                        Text {
                            text: root.now.getDate()
                            font.family: Theme.fontFamily
                            font.pixelSize: 48
                            font.weight: Font.Bold
                            color: Theme.colLayer0
                            visible: calendarGrid.isCurrentMonth
                        }

                        // Month and year
                        Column {
                            spacing: -4
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: Qt.formatDate(new Date(calendarGrid.year, calendarGrid.month, 1), "MMMM").toUpperCase()
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeBase + 4
                                font.weight: Font.Bold
                                color: Theme.colLayer0
                            }

                            Text {
                                text: calendarGrid.year
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeBase
                                font.weight: Font.Bold
                                color: Qt.alpha(Theme.colLayer0, 0.7)
                            }
                        }
                    }

                    // Location (from weather config)
                    Text {
                        text: {
                            const weatherEnabled = Config.options.calendar?.weather?.enabled ?? false;
                            if (!weatherEnabled)
                                return "";
                            const location = Config.options.calendar?.weather?.location ?? "";
                            return location.split(",")[0];
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.colLayer0
                        visible: text !== ""
                    }
                }

                // Clock - anchored to right (fixed position)
                MiniClock {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 56
                    height: 56
                }
            }
        }

        Rectangle {
            id: calendarCard
            Layout.fillWidth: true
            Layout.preferredHeight: calendarContent.implicitHeight + Theme.spacingBase * 2
            color: Theme.colLayer1
            radius: Theme.radiusBase

            property int firstDayOfWeek: 1  // Monday

            ColumnLayout {
                id: calendarContent
                anchors.fill: parent
                anchors.margins: Theme.spacingBase
                spacing: Theme.spacingBase

                // Navigation row with divider and buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingBase

                    // Horizontal divider (gradient line that fills left side)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2
                        Layout.alignment: Qt.AlignVCenter
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0.0
                                color: "transparent"
                            }
                            GradientStop {
                                position: 0.15
                                color: Theme.textSecondary
                            }
                            GradientStop {
                                position: 0.85
                                color: Theme.textSecondary
                            }
                            GradientStop {
                                position: 1.0
                                color: "transparent"
                            }
                        }
                    }

                    CircleButton {
                        icon: Icons.chevronLeft
                        onClicked: {
                            const newDate = new Date(calendarGrid.year, calendarGrid.month - 1, 1);
                            calendarGrid.year = newDate.getFullYear();
                            calendarGrid.month = newDate.getMonth();
                        }
                    }

                    CircleButton {
                        icon: Icons.today
                        onClicked: {
                            calendarGrid.month = root.now.getMonth();
                            calendarGrid.year = root.now.getFullYear();
                        }
                    }

                    CircleButton {
                        icon: Icons.chevronRight
                        onClicked: {
                            const newDate = new Date(calendarGrid.year, calendarGrid.month + 1, 1);
                            calendarGrid.year = newDate.getFullYear();
                            calendarGrid.month = newDate.getMonth();
                        }
                    }
                }

                // Day names header
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    rows: 1
                    columnSpacing: 0
                    rowSpacing: 0

                    Repeater {
                        model: 7

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    const dayIndex = (calendarCard.firstDayOfWeek + index) % 7;
                                    const dayNames = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
                                    return dayNames[dayIndex];
                                }
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: Theme.primary
                            }
                        }
                    }
                }

                // Calendar days grid
                GridLayout {
                    id: calendarGrid
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 2
                    rowSpacing: 2

                    property int month: root.now.getMonth()
                    property int year: root.now.getFullYear()

                    readonly property bool isCurrentMonth: {
                        return root.now.getMonth() === month && root.now.getFullYear() === year;
                    }

                    // Calculate days model
                    property var daysModel: {
                        const firstOfMonth = new Date(year, month, 1);
                        const lastOfMonth = new Date(year, month + 1, 0);
                        const daysInMonth = lastOfMonth.getDate();

                        const firstDayOfWeek = calendarCard.firstDayOfWeek;
                        const firstOfMonthDayOfWeek = firstOfMonth.getDay();

                        // Days before first of month
                        let daysBefore = (firstOfMonthDayOfWeek - firstDayOfWeek + 7) % 7;

                        // Days after last of month
                        const lastOfMonthDayOfWeek = lastOfMonth.getDay();
                        const daysAfter = (firstDayOfWeek - lastOfMonthDayOfWeek - 1 + 7) % 7;

                        const days = [];
                        const today = new Date();

                        // Previous month days
                        const prevMonth = new Date(year, month, 0);
                        const prevMonthDays = prevMonth.getDate();
                        for (let i = daysBefore - 1; i >= 0; i--) {
                            const day = prevMonthDays - i;
                            const prevYear = month === 0 ? year - 1 : year;
                            const prevMonthIdx = month === 0 ? 11 : month - 1;
                            days.push({
                                day: day,
                                month: prevMonthIdx,
                                year: prevYear,
                                today: false,
                                currentMonth: false,
                                holiday: HolidayService.getHoliday(prevYear, prevMonthIdx, day)
                            });
                        }

                        // Current month days
                        for (let day = 1; day <= daysInMonth; day++) {
                            const date = new Date(year, month, day);
                            const isToday = date.getFullYear() === today.getFullYear() && date.getMonth() === today.getMonth() && date.getDate() === today.getDate();
                            days.push({
                                day: day,
                                month: month,
                                year: year,
                                today: isToday,
                                currentMonth: true,
                                holiday: HolidayService.getHoliday(year, month, day)
                            });
                        }

                        // Next month days
                        for (let i = 1; i <= daysAfter; i++) {
                            const nextYear = month === 11 ? year + 1 : year;
                            const nextMonthIdx = month === 11 ? 0 : month + 1;
                            days.push({
                                day: i,
                                month: nextMonthIdx,
                                year: nextYear,
                                today: false,
                                currentMonth: false,
                                holiday: HolidayService.getHoliday(nextYear, nextMonthIdx, i)
                            });
                        }

                        return days;
                    }

                    Repeater {
                        model: calendarGrid.daysModel

                        Item {
                            id: dayCell
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32

                            property var event: modelData.holiday
                            property bool hasEvent: event !== null && event !== undefined
                            property string eventType: hasEvent ? event.type : ""
                            property bool showMarker: hasEvent && modelData.currentMonth

                            Rectangle {
                                width: 32
                                height: 32
                                anchors.centerIn: parent
                                radius: Theme.radiusBase
                                color: modelData.today ? Theme.colSecondary : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeBase
                                    font.weight: modelData.today ? Font.Bold : Font.Medium
                                    color: {
                                        if (modelData.today)
                                            return Theme.colLayer0;
                                        if (modelData.currentMonth)
                                            return Theme.textColor;
                                        return Theme.textSecondary;
                                    }
                                    opacity: modelData.currentMonth ? 1.0 : 0.4
                                }

                                // Dot for user events, diamond for public holidays
                                Rectangle {
                                    visible: dayCell.showMarker && (dayCell.eventType === "user" || dayCell.eventType === "public")
                                    width: 6
                                    height: 6
                                    radius: dayCell.eventType === "user" ? 3 : 0
                                    rotation: dayCell.eventType === "public" ? 45 : 0
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 2
                                    color: dayCell.eventType === "public" ? Theme.accentRed : Theme.primary
                                }

                                // Cross for namedays, asterisk for observances
                                Text {
                                    readonly property bool nameday: dayCell.eventType === "nameday"
                                    visible: dayCell.showMarker && (nameday || dayCell.eventType === "observance")
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: nameday ? -2 : -1
                                    text: nameday ? Icons.cross : "∗"
                                    font.pixelSize: nameday ? 12 : 10
                                    color: Theme.primary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onEntered: {
                                    if (dayCell.hasEvent) {
                                        dayTooltip.text = dayCell.event.name;
                                        dayTooltip.target = dayCell;
                                        dayTooltip.show();
                                    }
                                }
                                onExited: dayTooltip.hide()
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        dayTooltip.hide();
                                        const existingText = UserEventsService.getEvent(modelData.year, modelData.month, modelData.day) || "";
                                        inlineInput.show(modelData.year, modelData.month, modelData.day, existingText);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Tooltip for holidays
        Tooltip {
            id: dayTooltip
        }

        // Inline input for adding/editing events
        Rectangle {
            id: inlineInput
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? inputRow.implicitHeight + Theme.spacingBase * 2 : 0
            visible: false
            color: Theme.colLayer1
            radius: Theme.radiusBase
            border.color: Theme.colLayer0Border
            border.width: 1

            property int targetYear: 0
            property int targetMonth: 0
            property int targetDay: 0

            function show(year, month, day, text) {
                targetYear = year;
                targetMonth = month;
                targetDay = day;
                eventInput.text = text || "";
                visible = true;
            }

            function hide() {
                visible = false;
                eventInput.text = "";
            }

            onVisibleChanged: {
                if (visible) {
                    focusTimer.restart();
                }
            }

            Timer {
                id: focusTimer
                interval: 100
                onTriggered: eventInput.forceActiveFocus()
            }

            function save() {
                const trimmed = eventInput.text.trim();
                if (trimmed) {
                    UserEventsService.setEvent(targetYear, targetMonth, targetDay, trimmed);
                } else {
                    // Empty = delete
                    UserEventsService.deleteEvent(targetYear, targetMonth, targetDay);
                }
                hide();
            }

            RowLayout {
                id: inputRow
                anchors.fill: parent
                anchors.margins: Theme.spacingBase
                spacing: Theme.spacingSmall

                Text {
                    text: inlineInput.targetDay + "/" + (inlineInput.targetMonth + 1)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Bold
                    color: Theme.textSecondary
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: Theme.radiusSmall
                    color: Theme.colLayer0
                    border.color: eventInput.activeFocus ? Theme.primary : Theme.colLayer0Border
                    border.width: 1

                    TextInput {
                        id: eventInput
                        anchors.fill: parent
                        anchors.margins: 8
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeBase
                        color: Theme.textColor
                        clip: true

                        onAccepted: inlineInput.save()
                        Keys.onEscapePressed: inlineInput.hide()
                    }
                }

                InputAction {
                    glyph: "✓"
                    glyphColor: Theme.primaryText
                    baseColor: Theme.primary
                    hoverColor: Qt.darker(Theme.primary, 1.1)
                    onClicked: inlineInput.save()
                }

                InputAction {
                    glyph: "✕"
                    glyphColor: Theme.textColor
                    baseColor: Theme.colLayer1
                    hoverColor: Theme.colLayer2
                    onClicked: inlineInput.hide()
                }
            }
        }

        Loader {
            id: weatherLoader
            Layout.fillWidth: true
            active: Config.options.calendar?.weather?.enabled ?? false
            visible: active

            sourceComponent: WeatherCard {}
        }
    }

    component CircleButton: Rectangle {
        id: circleButton

        property string icon

        signal clicked

        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        radius: width / 2
        color: circleMouse.containsMouse ? Theme.colLayer2 : Theme.colLayer1
        border.width: 1
        border.color: Theme.colLayer0Border

        Text {
            anchors.centerIn: parent
            text: circleButton.icon
            font.family: Theme.fontFamilyIcons
            font.pixelSize: 14
            color: circleMouse.containsMouse ? Theme.primary : Theme.textColor
        }

        MouseArea {
            id: circleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: circleButton.clicked()
        }
    }

    component InputAction: Rectangle {
        id: inputAction

        property string glyph
        property color glyphColor
        property color baseColor
        property color hoverColor

        signal clicked

        implicitWidth: 32
        implicitHeight: 32
        radius: Theme.radiusSmall
        color: actionMouse.containsMouse ? hoverColor : baseColor

        Text {
            anchors.centerIn: parent
            text: inputAction.glyph
            font.pixelSize: 16
            color: inputAction.glyphColor
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: inputAction.clicked()
        }
    }
}
