pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "functions"

Singleton {
    id: root
    property QtObject m3colors
    property QtObject animation
    property QtObject animationCurves
    property QtObject colors
    property QtObject rounding
    property QtObject font
    property QtObject sizes

    m3colors: QtObject {
        property color m3secondary: "#D5C0D7"
        property color m3background: "#161217"
        property color m3onBackground: "#EAE0E7"
        property color m3surfaceContainerLow: "#1F1A1F"
        property color m3surfaceContainer: "#231E23"
        property color m3onSurfaceVariant: "#CFC3CD"
        property color m3outline: "#988E97"
        property color m3outlineVariant: "#4C444D"
        property color m3shadow: "#000000"
    }

    colors: QtObject {
        property color colLayer0: m3colors.m3background
        property color colLayer0Border: ColorUtils.mix(root.m3colors.m3outlineVariant, colLayer0, 0.4)
        property color colLayer1: m3colors.m3surfaceContainerLow
        property color colOnLayer1: m3colors.m3onSurfaceVariant
        property color colLayer2: m3colors.m3surfaceContainer
        property color colSecondary: m3colors.m3secondary
        property color colShadow: ColorUtils.transparentize(m3colors.m3shadow, 0.7)
    }

    rounding: QtObject {
        property int screenRounding: 23
        property int windowRounding: 18
    }

    font: QtObject {
        property QtObject family: QtObject {
            property string main: "sans-serif"
            property string expressive: "sans-serif"
        }
        property QtObject pixelSize: QtObject {
            property int smaller: 12
            property int small: 15
        }
    }

    animationCurves: QtObject {
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property real expressiveEffectsDuration: 200
    }

    animation: QtObject {
        property QtObject elementMoveEnter: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedDecel
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveEnter.duration
                    easing.type: root.animation.elementMoveEnter.type
                    easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        property QtObject elementMoveFast: QtObject {
            property int duration: animationCurves.expressiveEffectsDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveEffects
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
        }
    }

    sizes: QtObject {
        property real elevationMargin: 10
    }
}
