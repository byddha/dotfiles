import QtQuick
import "../Config"

Item {
    id: root

    // Current time (bind to external source or use internal)
    property var now: new Date()

    // Color properties for theming
    property color backgroundColor: Theme.primary
    property color clockColor: Theme.colLayer0
    property color secondHandColor: Theme.accentRed

    // Size (square)
    width: 64
    height: 64

    // Update timer for internal clock
    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Canvas {
        id: clockCanvas
        anchors.fill: parent

        onPaint: {
            const hours = root.now.getHours();
            const minutes = root.now.getMinutes();
            const seconds = root.now.getSeconds();

            const ctx = getContext("2d");
            ctx.reset();
            ctx.translate(width / 2, height / 2);

            const radius = Math.min(width, height) / 2;

            // Hour marks
            ctx.strokeStyle = Qt.alpha(root.clockColor, 0.7);
            ctx.lineWidth = 2;

            for (let i = 0; i < 12; i++) {
                const scaleFactor = (i % 3 === 0) ? 0.65 : 0.8;
                ctx.save();
                ctx.rotate(i * Math.PI / 6);
                ctx.beginPath();
                ctx.moveTo(0, -radius * scaleFactor);
                ctx.lineTo(0, -radius);
                ctx.stroke();
                ctx.restore();
            }

            // Hour hand
            ctx.save();
            const hourAngle = (hours % 12 + minutes / 60) * Math.PI / 6;
            ctx.rotate(hourAngle);
            ctx.strokeStyle = root.clockColor;
            ctx.lineWidth = 3;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(0, -radius * 0.5);
            ctx.stroke();
            ctx.restore();

            // Minute hand
            ctx.save();
            const minuteAngle = (minutes + seconds / 60) * Math.PI / 30;
            ctx.rotate(minuteAngle);
            ctx.strokeStyle = root.clockColor;
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(0, -radius * 0.75);
            ctx.stroke();
            ctx.restore();

            // Second hand
            ctx.save();
            const secondAngle = seconds * Math.PI / 30;
            ctx.rotate(secondAngle);
            ctx.strokeStyle = root.secondHandColor;
            ctx.lineWidth = 1.5;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(0, -radius * 0.85);
            ctx.stroke();
            ctx.restore();

            // Center dot
            ctx.beginPath();
            ctx.arc(0, 0, 3, 0, 2 * Math.PI);
            ctx.fillStyle = root.clockColor;
            ctx.fill();
        }

        Connections {
            target: root
            function onNowChanged() {
                clockCanvas.requestPaint();
            }
        }

        Component.onCompleted: requestPaint()
    }
}
