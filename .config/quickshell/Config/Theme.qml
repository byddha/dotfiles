pragma Singleton

import QtQuick
import Quickshell
import "../Utils"
import "../Services"

/**
 * Theme - Semantic base16 color theme system
 *
 * Maps base16 color palette to semantic UI colors.
 * All colors are reactive and update when ThemeService loads a new theme.
 */
Singleton {
    id: root

    function init() {
    // Initialization hook for shell.qml
    }

    // ========================================================================
    // BASE16 SEMANTIC COLOR MAPPING
    // ========================================================================

    // Background layers (darkest to lightest)
    property color colLayer0: ThemeService.base00        // Default background
    property color colLayer1: ThemeService.base01        // Lighter background (surfaces)
    property color colLayer2: ThemeService.base02        // Selection/hover background

    // Foreground colors
    property color textColor: ThemeService.base05        // Default text
    property color textSecondary: ThemeService.base04    // Muted text
    property color colOnLayer1: ThemeService.base04      // Text on layer1 surfaces

    // Accent colors (using base16 accent range: base08-0F)
    property color primary: ThemeService.base0D          // Primary accent (blue)
    property color primaryText: ThemeService.base00      // Text on primary (dark)
    property color colSecondary: ThemeService.base0E     // Secondary accent (purple/magenta)
    property color accentRed: ThemeService.base08        // Red accent (warnings/danger)
    property color accentOrange: ThemeService.base09     // Orange accent (boost/high values)

    // Surface and border colors
    property color surface: ThemeService.base01          // Surface background
    property color colLayer0Border: ColorUtils.mix(ThemeService.base02, ThemeService.base00, 0.4)

    // ========================================================================
    // TYPOGRAPHY
    // ========================================================================

    property string fontFamily: "JetBrainsMono Nerd Font Mono"
    property string fontFamilyIcons: "CaskaydiaCove Nerd Font Mono"

    property int fontSizeTiny: 12
    property int fontSizeSmall: 13
    property int fontSizeBase: 14

    // ========================================================================
    // SPACING & LAYOUT
    // ========================================================================

    property int spacingBase: 8
    property int spacingLarge: 16
    property int spacingSmall: 4

    property int radiusBase: 6
    property int radiusSmall: 4

    property int barHeight: 32
    property int iconSize: 20

    property int roundingScreen: 23
    property int roundingWindow: 18

    property real elevationMargin: 10

    // ========================================================================
    // ANIMATIONS
    // ========================================================================

    // Animation curves
    property QtObject animationCurves: QtObject {
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property real expressiveEffectsDuration: 200
    }

    // Animation presets
    property QtObject animation: QtObject {
        property QtObject elementMoveEnter: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: root.animationCurves.emphasizedDecel
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: Theme.animation.elementMoveEnter.duration
                    easing.type: Theme.animation.elementMoveEnter.type
                    easing.bezierCurve: Theme.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        property QtObject elementMoveFast: QtObject {
            property int duration: root.animationCurves.expressiveEffectsDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: root.animationCurves.expressiveEffects
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: Theme.animation.elementMoveFast.duration
                    easing.type: Theme.animation.elementMoveFast.type
                    easing.bezierCurve: Theme.animation.elementMoveFast.bezierCurve
                }
            }
        }
    }

    // ========================================================================
    // UTILITY FUNCTIONS
    // ========================================================================

    /**
     * Add alpha channel to color
     * @param color - Base color
     * @param opacity - Alpha value (0-1)
     * @returns Color with specified opacity
     */
    function alpha(color, opacity) {
        return Qt.rgba(color.r, color.g, color.b, opacity);
    }
}
