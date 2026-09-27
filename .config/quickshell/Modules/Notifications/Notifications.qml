import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Components/Notifications"

Scope {
    readonly property string primaryMonitorModel: Config.primaryMonitor

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: notificationPopup

            required property ShellScreen modelData
            screen: modelData

            visible: stack.entries.length > 0 && modelData.model === primaryMonitorModel

            WlrLayershell.namespace: "bidshell:notificationPopup"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 0

            anchors {
                right: true
                bottom: true
            }

            // Room on every side for the card shadows, as in DankMaterialShell's windowShadowPad.
            // The mask keeps that room click-through; the margins keep cards 2 * spacingBase from the edge.
            readonly property int shadowPad: 16

            WlrLayershell.margins {
                right: Theme.spacingBase * 2 - shadowPad
                bottom: Theme.spacingBase * 2 - shadowPad
            }

            mask: Region {
                item: stack
            }

            color: "transparent"
            // DankMaterialShell's NotificationMetrics.popupWidth (400) minus its 4 px card inset on each side.
            implicitWidth: 400 - Theme.spacingBase + shadowPad * 2
            // Fixed height so stack motion never resizes the surface; the mask limits input to the cards.
            implicitHeight: modelData.height - Theme.barHeight - Theme.spacingBase * 2

            // Single-window port of DMS NotificationPopupManager + NotificationPopup motion: newest card sits
            // in the corner, older ones are pushed up by a spring; cards slide in/out from the right edge.
            Item {
                id: stack

                // Shown cards, newest first; exiting cards stay until their exit animation ends.
                property var entries: []
                property double lastEnterMs: 0
                property double lastExitMs: 0
                // DMS NotificationPopupManager.popupSpacing (groupedListGap 2) + 2 * cardInset (4).
                readonly property real gap: 10
                readonly property int stagger: 100
                readonly property real extent: {
                    let max = 0;
                    for (const card of cards.children)
                        if (card.modelData !== undefined)
                            max = Math.max(max, card.offset + card.height);
                    return max;
                }

                function sync() {
                    const added = Notifications.popupList.filter(n => !entries.includes(n));
                    if (added.length > 0)
                        entries = [...added.reverse(), ...entries];
                }

                function remove(notif) {
                    entries = entries.filter(n => n !== notif);
                }

                // Distance from the stack bottom for a card, counting only cards in the layout (DMS _stackPositionFor).
                function positionFor(notif) {
                    let y = 0;
                    for (const n of entries) {
                        if (n === notif)
                            return y;
                        const card = cards.cardFor(n);
                        if (card?.inLayout)
                            y += card.height + gap;
                    }
                    return y;
                }

                // DMS _pumpMotion: entries and exits start at least `stagger` ms apart.
                function staggerDelay(kind) {
                    const now = Date.now();
                    const key = kind === "enter" ? "lastEnterMs" : "lastExitMs";
                    const start = Math.max(now, stack[key] + stagger);
                    stack[key] = start;
                    return start - now;
                }

                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: notificationPopup.shadowPad
                anchors.rightMargin: notificationPopup.shadowPad
                width: parent.width - notificationPopup.shadowPad * 2
                height: extent

                Connections {
                    target: Notifications
                    function onPopupListChanged() {
                        stack.sync();
                    }
                }
                Component.onCompleted: sync()

                Item {
                    id: cards

                    function cardFor(notif) {
                        for (const card of children)
                            if (card.modelData === notif)
                                return card;
                        return null;
                    }

                    anchors.fill: parent

                    Repeater {
                        model: ScriptModel {
                            values: stack.entries
                        }

                        NotificationCard {
                            id: card

                            required property var modelData
                            readonly property bool live: Notifications.popupList.includes(modelData)
                            property bool entered: false
                            property bool exiting: false
                            readonly property bool inLayout: entered && !exiting
                            property real progress: 0
                            // DMS SpringMotion driven by springPreset("default", 200): stiffness 1875, damping 60.
                            property real offset: 0
                            property real velocity: 0
                            readonly property real targetOffset: stack.positionFor(modelData)

                            function startExit() {
                                if (exiting)
                                    return;
                                exiting = true;
                                enterAnim.stop();
                                exitTimer.interval = stack.staggerDelay("exit");
                                exitTimer.start();
                            }

                            notificationObject: modelData
                            popup: true
                            width: stack.width
                            y: stack.height - offset - height
                            opacity: progress
                            scale: 0.96 + 0.04 * progress
                            transform: Translate {
                                x: card.width * (1 - card.progress)
                            }

                            onLiveChanged: {
                                if (!live && !entered)
                                    stack.remove(modelData);
                                else if (!live)
                                    startExit();
                            }
                            Component.onCompleted: {
                                offset = targetOffset;
                                enterTimer.interval = stack.staggerDelay("enter");
                                enterTimer.start();
                            }

                            Timer {
                                id: enterTimer
                                onTriggered: {
                                    card.offset = card.targetOffset;
                                    card.entered = true;
                                    enterAnim.start();
                                }
                            }

                            Timer {
                                id: exitTimer
                                onTriggered: exitAnim.start()
                            }

                            FrameAnimation {
                                running: Math.abs(card.targetOffset - card.offset) > 0.05 || Math.abs(card.velocity) > 0.05
                                onTriggered: {
                                    const frame = Math.min(frameTime, 1 / 30);
                                    const steps = Math.max(1, Math.ceil(frame * 240));
                                    const step = frame / steps;
                                    for (let i = 0; i < steps; i++) {
                                        card.velocity += (1875 * (card.targetOffset - card.offset) - 60 * card.velocity) * step;
                                        card.offset += card.velocity * step;
                                    }
                                    if (Math.abs(card.targetOffset - card.offset) <= 0.05 && Math.abs(card.velocity) <= 0.05) {
                                        card.offset = card.targetOffset;
                                        card.velocity = 0;
                                    }
                                }
                            }

                            // DMS enterAnimation: notificationEnterDuration (175) on emphasizedDecel.
                            NumberAnimation {
                                id: enterAnim
                                target: card
                                property: "progress"
                                to: 1
                                duration: 175
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
                            }

                            // DMS exitAnim: notificationExitDuration (150) on standardAccel.
                            NumberAnimation {
                                id: exitAnim
                                target: card
                                property: "progress"
                                to: 0
                                duration: 150
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: [0.3, 0, 1, 1, 1, 1]
                                onFinished: stack.remove(card.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
