import QtQuick
import QtQuick.Layouts
import "../Config"
import "../Services"

Item {
    id: root

    property var temperatures: []  // Array of temperature values
    property var times: []         // Array of time strings (e.g., "2PM")
    property int hours: 12         // Number of hours to show

    implicitHeight: 80
    implicitWidth: 300

    Canvas {
        id: graphCanvas
        anchors.fill: parent
        anchors.leftMargin: 30   // Space for Y-axis labels
        anchors.rightMargin: 5
        anchors.topMargin: 10
        anchors.bottomMargin: 20  // Space for X-axis labels

        onPaint: {
            if (root.temperatures.length === 0)
                return;

            const ctx = getContext("2d");
            ctx.reset();

            const temps = root.temperatures;
            const graphWidth = width;
            const graphHeight = height;

            // Calculate min/max for scaling
            let minTemp = Math.min(...temps);
            let maxTemp = Math.max(...temps);

            // Add padding to range
            const range = maxTemp - minTemp;
            if (range < 4) {
                // Ensure minimum range of 4 degrees
                const mid = (minTemp + maxTemp) / 2;
                minTemp = mid - 2;
                maxTemp = mid + 2;
            } else {
                minTemp -= 1;
                maxTemp += 1;
            }

            // Helper to convert temp to Y position
            function tempToY(temp) {
                return graphHeight - ((temp - minTemp) / (maxTemp - minTemp)) * graphHeight;
            }

            // Helper to get X position for index
            function indexToX(i) {
                return (i / (temps.length - 1)) * graphWidth;
            }

            // Draw grid lines (horizontal)
            ctx.strokeStyle = Qt.alpha(Theme.textSecondary, 0.2);
            ctx.lineWidth = 1;
            for (let i = 0; i <= 2; i++) {
                const y = (i / 2) * graphHeight;
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(graphWidth, y);
                ctx.stroke();
            }

            // Draw the temperature line with smooth curves
            ctx.strokeStyle = Theme.primary;
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.beginPath();

            for (let i = 0; i < temps.length; i++) {
                const x = indexToX(i);
                const y = tempToY(temps[i]);

                if (i === 0) {
                    ctx.moveTo(x, y);
                } else {
                    // Use quadratic curve for smooth lines
                    const prevX = indexToX(i - 1);
                    const prevY = tempToY(temps[i - 1]);
                    const cpX = (prevX + x) / 2;
                    ctx.quadraticCurveTo(cpX, prevY, cpX, (prevY + y) / 2);
                    ctx.quadraticCurveTo(cpX, y, x, y);
                }
            }
            ctx.stroke();

            // Draw dots at each data point (skip first - already shown above)
            ctx.fillStyle = Theme.primary;
            for (let i = 1; i < temps.length; i++) {
                const x = indexToX(i);
                const y = tempToY(temps[i]);
                ctx.beginPath();
                ctx.arc(x, y, 3, 0, 2 * Math.PI);
                ctx.fill();
            }

            // Draw temperature labels above each point (skip first)
            ctx.fillStyle = Theme.textSecondary;
            ctx.font = "10px sans-serif";
            ctx.textAlign = "center";
            for (let i = 1; i < temps.length; i++) {
                // Only show every 2nd label to avoid crowding
                if (i % 2 !== 0 && i !== temps.length - 1)
                    continue;

                const x = indexToX(i);
                const y = tempToY(temps[i]);
                const labelY = y < 16 ? y + 14 : y - 8;
                ctx.fillText(Math.round(temps[i]) + "°", x, labelY);
            }
        }

        Connections {
            target: root
            function onTemperaturesChanged() {
                graphCanvas.requestPaint();
            }
        }

        Component.onCompleted: requestPaint()
    }

    // Y-axis labels (max at top, min at bottom)
    Item {
        anchors.left: parent.left
        anchors.top: graphCanvas.top
        anchors.bottom: graphCanvas.bottom
        width: 28

        Text {
            text: {
                if (root.temperatures.length === 0)
                    return "";
                const max = Math.max(...root.temperatures);
                return Math.round(max) + "°";
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.textSecondary
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.rightMargin: 4
        }

        Text {
            text: {
                if (root.temperatures.length === 0)
                    return "";
                const min = Math.min(...root.temperatures);
                return Math.round(min) + "°";
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeTiny
            color: Theme.textSecondary
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: 4
        }
    }

    // X-axis time labels
    Row {
        anchors.left: graphCanvas.left
        anchors.right: graphCanvas.right
        anchors.top: graphCanvas.bottom
        anchors.topMargin: 2
        height: 18

        Repeater {
            model: root.times.length > 0 ? Math.min(6, root.times.length) : 0

            Text {
                width: graphCanvas.width / (Math.min(6, root.times.length) - 1 || 1)
                text: {
                    const step = Math.floor(root.times.length / 6);
                    const idx = index * step;
                    return root.times[idx] || "";
                }
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.textSecondary
                horizontalAlignment: index === 0 ? Text.AlignLeft : (index === Math.min(6, root.times.length) - 1 ? Text.AlignRight : Text.AlignHCenter)
            }
        }
    }
}
