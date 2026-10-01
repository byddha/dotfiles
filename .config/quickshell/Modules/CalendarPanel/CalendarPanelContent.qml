import QtQuick
import QtQuick.Layouts
import "../../Config"

// Calendar and weather side by side
RowLayout {
    id: root

    // Every opening starts clean, on the current month
    function reset() {
        calendar.closeEdit();
        calendar.hoveredDay = null;
        calendar.showToday();
    }

    spacing: Theme.spacingBase

    MonthCalendar {
        id: calendar

        Layout.preferredWidth: 356
        Layout.fillHeight: true
    }

    WeatherCard {
        Layout.preferredWidth: 356
        Layout.fillHeight: true
    }
}
