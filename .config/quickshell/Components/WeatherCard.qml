import QtQuick
import QtQuick.Layouts
import "../Config"
import "../Services"

Rectangle {
    id: root

    property int forecastDays: 5

    readonly property bool weatherReady: WeatherService.weatherReady

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
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: weatherReady ? WeatherService.weatherSymbolFromCode(WeatherService.data.weather.current.weather_code) : ""
                    font.family: Theme.fontFamilyIcons
                    font.pointSize: 40
                    color: Theme.primary
                }

                // Temperature and location
                ColumnLayout {
                    spacing: 2

                    // Location name
                    Text {
                        text: {
                            if (!weatherReady)
                                return "";
                            const location = Config.options.calendar?.weather?.location ?? "London";
                            return location.split(",")[0];
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeBase + 2
                        font.weight: Font.Bold
                        color: Theme.textColor
                    }

                    // Temperature
                    RowLayout {
                        spacing: 4

                        Text {
                            visible: weatherReady
                            text: weatherReady ? Math.round(WeatherService.data.weather.current.temperature_2m) + "°C" : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeBase + 4
                            font.weight: Font.Bold
                            color: Theme.textColor
                        }

                        Text {
                            text: weatherReady && WeatherService.data.weather.timezone_abbreviation ? "(" + WeatherService.data.weather.timezone_abbreviation + ")" : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeTiny
                            color: Theme.textSecondary
                            visible: weatherReady
                        }
                    }

                    // Weather description
                    Text {
                        visible: weatherReady
                        text: weatherReady ? WeatherService.weatherDescriptionFromCode(WeatherService.data.weather.current.weather_code) : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textSecondary
                    }

                    // Weather details row with icons
                    Row {
                        visible: weatherReady
                        spacing: Theme.spacingBase

                        // Feels like
                        Row {
                            spacing: 3
                            Text {
                                text: Icons.thermometer
                                font.family: Theme.fontFamilyIcons
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.textSecondary
                            }
                            Text {
                                text: {
                                    if (!weatherReady)
                                        return "";
                                    const feelsLike = WeatherService.data.weather.current?.apparent_temperature ?? WeatherService.data.weather.current.temperature_2m;
                                    return "Feels " + Math.round(feelsLike) + "°";
                                }
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.textSecondary
                            }
                        }

                        // Humidity
                        Row {
                            spacing: 3
                            Text {
                                text: Icons.humidity
                                font.family: Theme.fontFamilyIcons
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.textSecondary
                            }
                            Text {
                                text: weatherReady ? (WeatherService.data.weather.current?.relative_humidity_2m ?? 0) + "%" : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.textSecondary
                            }
                        }

                        // Wind
                        Row {
                            spacing: 3
                            Text {
                                text: Icons.wind
                                font.family: Theme.fontFamilyIcons
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.textSecondary
                            }
                            Text {
                                text: weatherReady ? Math.round(WeatherService.data.weather.current.wind_speed_10m) + "km/h" : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.textSecondary
                            }
                        }

                        // Precipitation
                        Row {
                            spacing: 3
                            Text {
                                text: Icons.rain
                                font.family: Theme.fontFamilyIcons
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.textSecondary
                            }
                            Text {
                                text: {
                                    if (!weatherReady)
                                        return "";
                                    const hourly = WeatherService.data.weather.hourly;
                                    if (hourly?.precipitation_probability) {
                                        const now = new Date();
                                        const currentHour = now.getHours();
                                        const today = now.getDate();
                                        for (let i = 0; i < hourly.time.length; i++) {
                                            const t = new Date(hourly.time[i]);
                                            if (t.getDate() === today && t.getHours() === currentHour) {
                                                return hourly.precipitation_probability[i] + "%";
                                            }
                                        }
                                    }
                                    return "0%";
                                }
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.textSecondary
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
                const hourly = WeatherService.data.weather.hourly;
                const currentHour = new Date().getHours();

                // Find current hour index in the hourly data
                const times = hourly.time;
                let startIdx = 0;
                for (let i = 0; i < times.length; i++) {
                    const hour = new Date(times[i]).getHours();
                    const day = new Date(times[i]).getDate();
                    const today = new Date().getDate();
                    if (day === today && hour >= currentHour) {
                        startIdx = i;
                        break;
                    }
                }

                // Get next 12 hours
                return hourly.temperature_2m.slice(startIdx, startIdx + 12);
            }
            times: {
                if (!weatherReady || !WeatherService.data.weather?.hourly)
                    return [];
                const hourly = WeatherService.data.weather.hourly;
                const currentHour = new Date().getHours();

                // Find current hour index
                const times = hourly.time;
                let startIdx = 0;
                for (let i = 0; i < times.length; i++) {
                    const hour = new Date(times[i]).getHours();
                    const day = new Date(times[i]).getDate();
                    const today = new Date().getDate();
                    if (day === today && hour >= currentHour) {
                        startIdx = i;
                        break;
                    }
                }

                // Format next 12 hours as time strings
                return hourly.time.slice(startIdx, startIdx + 12).map((t, i) => {
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
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            const dateStr = WeatherService.data.weather.daily.time[index];
                            const date = new Date(dateStr.replace(/-/g, "/"));
                            return Qt.formatDate(date, "ddd");
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textColor
                    }

                    // Weather icon
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: WeatherService.weatherSymbolFromCode(WeatherService.data.weather.daily.weather_code[index])
                        font.family: Theme.fontFamilyIcons
                        font.pointSize: 28
                        color: Theme.primary
                    }

                    // High/Low temps
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            const max = WeatherService.data.weather.daily.temperature_2m_max[index];
                            const min = WeatherService.data.weather.daily.temperature_2m_min[index];
                            return Math.round(max) + "°/" + Math.round(min) + "°";
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTiny
                        color: Theme.textSecondary
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

                Text {
                    text: Icons.spinner  // spinner icon
                    font.family: Theme.fontFamilyIcons
                    font.pixelSize: Theme.fontSizeBase
                    color: Theme.textSecondary

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: !weatherReady
                    }
                }

                Text {
                    text: "Loading weather..."
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textSecondary
                }
            }
        }
    }
}
