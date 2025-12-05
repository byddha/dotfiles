import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Utils"
import "../../Services"
import "../../Components"

/**
 * CalendarPanelContent - Content for the calendar popup panel
 *
 * Contains:
 * - Banner with date display and analog/digital clock
 * - Calendar grid with month navigation
 * - Weather card (optional)
 */
Item {
    id: root

    property var now: new Date()

    implicitWidth: 380
    implicitHeight: content.implicitHeight

    // Update time every minute for calendar
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // Also update on second for the clock
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

        // ====================================================================
        // BANNER - Date display with clock
        // ====================================================================
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
                    backgroundColor: Theme.primary
                    clockColor: Theme.colLayer0
                    secondHandColor: Theme.accentRed
                    now: root.now
                }
            }
        }

        // ====================================================================
        // CALENDAR GRID
        // ====================================================================
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

                    // Previous month button (circular)
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: width / 2
                        color: prevMouseArea.containsMouse ? Theme.colLayer2 : Theme.colLayer1
                        border.width: 1
                        border.color: Theme.colLayer0Border

                        Text {
                            anchors.centerIn: parent
                            text: Icons.chevronLeft
                            font.pixelSize: 14
                            font.family: Theme.fontFamilyIcons
                            color: prevMouseArea.containsMouse ? Theme.primary : Theme.textColor
                        }

                        MouseArea {
                            id: prevMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const newDate = new Date(calendarGrid.year, calendarGrid.month - 1, 1);
                                calendarGrid.year = newDate.getFullYear();
                                calendarGrid.month = newDate.getMonth();
                            }
                        }
                    }

                    // Today button (circular)
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: width / 2
                        color: todayMouseArea.containsMouse ? Theme.colLayer2 : Theme.colLayer1
                        border.width: 1
                        border.color: Theme.colLayer0Border

                        Text {
                            anchors.centerIn: parent
                            text: Icons.today
                            font.family: Theme.fontFamilyIcons
                            font.pixelSize: 14
                            color: todayMouseArea.containsMouse ? Theme.primary : Theme.textColor
                        }

                        MouseArea {
                            id: todayMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                calendarGrid.month = root.now.getMonth();
                                calendarGrid.year = root.now.getFullYear();
                            }
                        }
                    }

                    // Next month button (circular)
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: width / 2
                        color: nextMouseArea.containsMouse ? Theme.colLayer2 : Theme.colLayer1
                        border.width: 1
                        border.color: Theme.colLayer0Border

                        Text {
                            anchors.centerIn: parent
                            text: Icons.chevronRight
                            font.family: Theme.fontFamilyIcons
                            font.pixelSize: 14
                            color: nextMouseArea.containsMouse ? Theme.primary : Theme.textColor
                        }

                        MouseArea {
                            id: nextMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const newDate = new Date(calendarGrid.year, calendarGrid.month + 1, 1);
                                calendarGrid.year = newDate.getFullYear();
                                calendarGrid.month = newDate.getMonth();
                            }
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
                            days.push({
                                day: day,
                                month: month - 1,
                                year: month === 0 ? year - 1 : year,
                                today: false,
                                currentMonth: false
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
                                currentMonth: true
                            });
                        }

                        // Next month days
                        for (let i = 1; i <= daysAfter; i++) {
                            days.push({
                                day: i,
                                month: month + 1,
                                year: month === 11 ? year + 1 : year,
                                today: false,
                                currentMonth: false
                            });
                        }

                        return days;
                    }

                    Repeater {
                        model: calendarGrid.daysModel

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32

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
                            }
                        }
                    }
                }
            }
        }

        // ====================================================================
        // WEATHER SECTION (conditional)
        // ====================================================================
        Loader {
            id: weatherLoader
            Layout.fillWidth: true
            active: Config.options.calendar?.weather?.enabled ?? false
            visible: active

            sourceComponent: WeatherCard {
                forecastDays: 5
            }
        }
    }
}
