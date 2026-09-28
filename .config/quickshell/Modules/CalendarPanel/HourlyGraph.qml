pragma ComponentBehavior: Bound
import QtQuick
import "../../Config"
import "../../Components"

// Temperature line over the next hours: values above every second point, hours under them.
// No axes or gridlines; the first point is now.
Item {
    id: root

    // [{ label, temperature }]
    property var hours: []

    // The line lives between these heights; values sit above it and hours below
    readonly property real plotTop: 16
    readonly property real plotBottom: 44
    // Keeps the edge points' rings and labels inside the item
    readonly property real inset: 5
    readonly property real low: Math.min(...hours.map(hour => hour.temperature))
    readonly property real high: Math.max(...hours.map(hour => hour.temperature))

    function pointX(i) {
        return hours.length < 2 ? width / 2 : inset + i * (width - inset * 2) / (hours.length - 1);
    }

    function pointY(i) {
        if (high === low)
            return (plotTop + plotBottom) / 2;
        return plotTop + (high - hours[i].temperature) / (high - low) * (plotBottom - plotTop);
    }

    implicitHeight: 64

    onHoursChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()

    Canvas {
        id: canvas

        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const count = root.hours.length;
            if (count < 2)
                return;

            const fill = ctx.createLinearGradient(0, root.plotTop, 0, root.plotBottom);
            fill.addColorStop(0, Theme.alpha(Theme.primary, 0.22));
            fill.addColorStop(1, Theme.alpha(Theme.primary, 0));
            ctx.beginPath();
            ctx.moveTo(root.pointX(0), root.plotBottom);
            for (let i = 0; i < count; i++)
                ctx.lineTo(root.pointX(i), root.pointY(i));
            ctx.lineTo(root.pointX(count - 1), root.plotBottom);
            ctx.closePath();
            ctx.fillStyle = fill;
            ctx.fill();

            ctx.beginPath();
            for (let i = 0; i < count; i++)
                ctx.lineTo(root.pointX(i), root.pointY(i));
            ctx.strokeStyle = Theme.primary;
            ctx.lineWidth = 2;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.stroke();

            ctx.fillStyle = Theme.primary;
            for (let i = 1; i < count; i++) {
                ctx.beginPath();
                ctx.arc(root.pointX(i), root.pointY(i), 2, 0, 2 * Math.PI);
                ctx.fill();
            }

            // Now: a bigger point with a ring in the card's color
            ctx.beginPath();
            ctx.arc(root.pointX(0), root.pointY(0), 4, 0, 2 * Math.PI);
            ctx.fillStyle = Theme.primary;
            ctx.fill();
            ctx.lineWidth = 2;
            ctx.strokeStyle = Theme.cardSurface;
            ctx.stroke();
        }

        Connections {
            target: Theme

            function onPrimaryChanged() {
                canvas.requestPaint();
            }
        }
    }

    Repeater {
        model: root.hours

        Item {
            id: hour

            required property var modelData
            required property int index
            // Labels at the ends line up with the edges instead of hanging over them
            readonly property real anchorX: index === 0 ? 0 : index === root.hours.length - 1 ? root.width : root.pointX(index)
            readonly property real align: index === 0 ? 0 : index === root.hours.length - 1 ? 1 : 0.5

            visible: index % 2 === 0

            StyledText {
                x: hour.anchorX - implicitWidth * hour.align
                y: root.pointY(hour.index) - 9 - implicitHeight
                role: "secondary"
                text: `${Math.round(hour.modelData.temperature)}°`
                font.pixelSize: Theme.fontSizeTiny
                font.weight: Font.Medium
            }

            StyledText {
                x: hour.anchorX - implicitWidth * hour.align
                y: root.height - implicitHeight
                role: "tertiary"
                text: hour.modelData.label
                font.pixelSize: Theme.fontSizeTiny
            }
        }
    }
}
