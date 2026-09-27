import QtQuick
import "../Config"

Item {
    id: root

    // Overwritten every second by the internal timer, so an external binding only seeds it
    property var now: new Date()

    property color clockColor: Theme.colLayer0
    property color secondHandColor: Theme.accentRed

    // Size (square)
    width: 64
    height: 64

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Canvas {
        id: clockCanvas
        anchors.fill: parent

        function drawHand(ctx, angle, color, lineWidth, length) {
            ctx.save();
            ctx.rotate(angle);
            ctx.strokeStyle = color;
            ctx.lineWidth = lineWidth;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(0, -length);
            ctx.stroke();
            ctx.restore();
        }

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

            drawHand(ctx, (hours % 12 + minutes / 60) * Math.PI / 6, root.clockColor, 3, radius * 0.5);
            drawHand(ctx, (minutes + seconds / 60) * Math.PI / 30, root.clockColor, 2, radius * 0.75);
            drawHand(ctx, seconds * Math.PI / 30, root.secondHandColor, 1.5, radius * 0.85);

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
