import QtQuick
import QtQuick.Layouts
import "../Config"
import "../Services"

Rectangle {
    id: root

    property int forecastDays: 5

    readonly property bool weatherReady: WeatherService.weatherReady
    // First hourly slot today at or after the current hour; -1 when there is none
    readonly property int currentHourIndex: {
        const hourly = weatherReady ? WeatherService.data.weather?.hourly : undefined;
        if (!hourly)
            return -1;
        const now = new Date();
        return hourly.time.findIndex(t => {
            const date = new Date(t);
            return date.getDate() === now.getDate() && date.getHours() >= now.getHours();
        });
    }

    color: Theme.colLayer1
    radius: Theme.radiusBase
    implicitHeight: Math.max(100, content.implicitHeight + Theme.spacingLarge * 2)

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: Theme.spacingBase
        clip: true

        // Current weather row
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingBase

            Item {
                Layout.preferredWidth: 2
            }

            RowLayout {
                spacing: Theme.spacingLarge
                Layout.fillWidth: true

                // Weather icon
                Icon {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    text: weatherReady ? WeatherService.glyphFromCode(WeatherService.data.weather.current.weather_code, WeatherService.data.weather.current.is_day === 1) : ""
                    size: 44
                    color: Theme.primary
                }

                // Temperature and location
                ColumnLayout {
                    spacing: 2

                    // Location name
                    StyledText {
                        text: weatherReady ? WeatherService.location : ""
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Bold
                        color: Theme.textColor
                    }

                    // Temperature
                    RowLayout {
                        spacing: 4

                        StyledText {
                            visible: weatherReady
                            text: weatherReady ? Math.round(WeatherService.data.weather.current.temperature_2m) + "°C" : ""
                            font.pixelSize: Theme.fontSizeTitle
                            font.weight: Font.Bold
                            color: Theme.textColor
                        }

                        StyledText {
                            text: weatherReady && WeatherService.data.weather.timezone_abbreviation ? "(" + WeatherService.data.weather.timezone_abbreviation + ")" : ""
                            role: "secondary"
                            font.pixelSize: Theme.fontSizeTiny
                            visible: weatherReady
                        }
                    }

                    // Weather description
                    StyledText {
                        visible: weatherReady
                        text: weatherReady ? WeatherService.weatherDescriptionFromCode(WeatherService.data.weather.current.weather_code) : ""
                        role: "secondary"
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    // Weather details row with icons
                    Row {
                        visible: weatherReady
                        spacing: Theme.spacingBase

                        WeatherDetail {
                            icon: Lucide.thermometer
                            label: {
                                if (!weatherReady)
                                    return "";
                                const feelsLike = WeatherService.data.weather.current?.apparent_temperature ?? WeatherService.data.weather.current.temperature_2m;
                                return "Feels " + Math.round(feelsLike) + "°";
                            }
                        }

                        WeatherDetail {
                            icon: Lucide.droplets
                            label: weatherReady ? (WeatherService.data.weather.current?.relative_humidity_2m ?? 0) + "%" : ""
                        }

                        WeatherDetail {
                            icon: Lucide.wind
                            label: weatherReady ? Math.round(WeatherService.data.weather.current.wind_speed_10m) + "km/h" : ""
                        }

                        WeatherDetail {
                            icon: Lucide.umbrella
                            label: {
                                if (!weatherReady)
                                    return "";
                                const hourly = WeatherService.data.weather.hourly;
                                const i = root.currentHourIndex;
                                // currentHourIndex may land on a later hour; only the current hour's value is shown
                                if (hourly?.precipitation_probability && i >= 0 && new Date(hourly.time[i]).getHours() === new Date().getHours())
                                    return hourly.precipitation_probability[i] + "%";
                                return "0%";
                            }
                        }
                    }
                }
            }
        }

        // Divider
        Rectangle {
            visible: weatherReady
            Layout.fillWidth: true
            height: 1
            color: Theme.colLayer0Border
        }

        // Hourly temperature graph
        HourlyGraph {
            id: hourlyGraph
            visible: weatherReady && (WeatherService.data.weather?.hourly !== undefined)
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            temperatures: {
                if (!weatherReady || !WeatherService.data.weather?.hourly)
                    return [];
                const startIdx = Math.max(0, root.currentHourIndex);
                return WeatherService.data.weather.hourly.temperature_2m.slice(startIdx, startIdx + 12);
            }
            times: {
                if (!weatherReady || !WeatherService.data.weather?.hourly)
                    return [];
                const startIdx = Math.max(0, root.currentHourIndex);
                return WeatherService.data.weather.hourly.time.slice(startIdx, startIdx + 12).map((t, i) => {
                    if (i === 0)
                        return "Now";
                    const date = new Date(t);
                    const hour = date.getHours();
                    if (hour === 0)
                        return "12AM";
                    if (hour === 12)
                        return "12PM";
                    return hour > 12 ? (hour - 12) + "PM" : hour + "AM";
                });
            }
        }

        // Divider before forecast
        Rectangle {
            visible: weatherReady && (WeatherService.data.weather?.hourly !== undefined)
            Layout.fillWidth: true
            height: 1
            color: Theme.colLayer0Border
        }

        // Forecast row
        RowLayout {
            visible: weatherReady
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spacingBase

            Repeater {
                model: weatherReady ? Math.min(root.forecastDays, WeatherService.data.weather.daily.time.length) : 0

                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Item {
                        Layout.fillWidth: true
                    }

                    // Day name
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            const dateStr = WeatherService.data.weather.daily.time[index];
                            const date = new Date(dateStr.replace(/-/g, "/"));
                            return Qt.formatDate(date, "ddd");
                        }
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Normal
                        color: Theme.textColor
                    }

                    // Weather icon
                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        text: WeatherService.glyphFromCode(WeatherService.data.weather.daily.weather_code[index], true)
                        size: 28
                        color: Theme.primary
                    }

                    // High/Low temps
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            const max = WeatherService.data.weather.daily.temperature_2m_max[index];
                            const min = WeatherService.data.weather.daily.temperature_2m_min[index];
                            return Math.round(max) + "°/" + Math.round(min) + "°";
                        }
                        role: "secondary"
                        font.pixelSize: Theme.fontSizeTiny
                    }
                }
            }
        }

        // Loading indicator
        Item {
            visible: !weatherReady
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            RowLayout {
                anchors.centerIn: parent
                spacing: Theme.spacingBase

                Spinner {
                    size: Theme.iconSizeSmall
                    color: Theme.textSecondary
                }

                StyledText {
                    text: "Loading weather..."
                    role: "secondary"
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }
    }

    component WeatherDetail: Row {
        id: detail

        property string icon
        property string label

        spacing: 3

        Icon {
            text: detail.icon
            size: Theme.iconSizeSmall
            color: Theme.textSecondary
        }

        StyledText {
            text: detail.label
            role: "secondary"
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
