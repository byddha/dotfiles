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

    // ========================================================================
    // SEMANTIC COLOR MAPPING
    // ========================================================================

    // Background layers (darkest to lightest)
    property color colLayer0: ThemeService.background            // Default background
    property color colLayer1: ThemeService.surfaceContainer      // Lighter background (surfaces)
    property color colLayer2: ThemeService.surfaceContainerHigh  // Selection/hover background
    property color colLayer3: ThemeService.surfaceContainerHighest

    // Foreground colors
    property color textColor: ThemeService.surfaceText             // Default text
    property color textSecondary: ThemeService.surfaceVariantText  // Muted text
    property color colOnLayer1: ThemeService.surfaceVariantText    // Text on layer1 surfaces

    // Accent colors
    property color primary: ThemeService.primary                 // Primary accent
    property color primaryText: ThemeService.primaryTextColor           // Text on primary
    property color colSecondary: ThemeService.secondary          // Secondary accent
    property color secondaryContainer: ThemeService.secondaryContainer
    property color secondaryContainerText: ThemeService.secondaryContainerText
    property color accentRed: ThemeService.error                 // Red accent (warnings/danger)
    property color accentRedText: ThemeService.errorText
    property color accentOrange: ThemeService.base09             // Orange accent (no material role for it)
    property color accentYellow: ThemeService.base0A
    property color accentGreen: ThemeService.base0B

    // Surface and border colors
    property color surface: ThemeService.surfaceContainer        // Surface background
    property color colLayer0Border: ColorUtils.mix(ThemeService.surfaceContainerHigh, ThemeService.background, 0.4)
    // DankMaterialShell's popup border: outline at 35% (BlurService.borderColor)
    property color popupBorder: alpha(ThemeService.outline, 0.35)
    property color outline: ThemeService.outline
    property color outlineVariant: ThemeService.outlineVariant

    // State layer opacities: one overlay rule for every interactive element
    readonly property real stateHover: 0.08
    readonly property real statePressed: 0.12
    readonly property real stateSelected: 0.12
    readonly property real stateDisabled: 0.38

    // ========================================================================
    // TYPOGRAPHY
    // ========================================================================

    property string fontFamily: "JetBrainsMono Nerd Font Mono"
    property string fontFamilyIcons: "CaskaydiaCove Nerd Font Mono"
    // Full-size glyphs: the Mono font shrinks wide glyphs to one cell
    property string fontFamilyGlyphs: "Symbols Nerd Font"

    // Bundled, so the shell never depends on what the system has installed and Lucide's
    // codepoints stay pinned to the version Icons maps them from
    readonly property string fontUi: geistLoader.name
    readonly property string fontIcons: lucideLoader.name

    readonly property FontLoader geistLoader: FontLoader {
        source: Quickshell.shellPath("assets/fonts/geist/Geist-Variable.ttf")
    }
    readonly property FontLoader lucideLoader: FontLoader {
        source: Quickshell.shellPath("assets/fonts/lucide/lucide.ttf")
    }

    property int fontSizeTiny: 12
    property int fontSizeSmall: 13
    property int fontSizeBase: 14

    // ========================================================================
    // SPACING & LAYOUT
    // ========================================================================

    property int spacingBase: 8
    readonly property int sidebarWidth: 400
    readonly property int whichKeyFontSize: 24
    property int spacingLarge: 16
    property int spacingSmall: 4

    property int radiusBase: 6
    // Matches Hyprland decoration:rounding, as DankMaterialShell's windowRadius does
    readonly property int radiusWindow: 10
    property int radiusSmall: 4

    property int barHeight: 32
    property int iconSize: 20

    property int roundingScreen: 23
    property int roundingWindow: 10

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
        const c = Qt.color(color);
        return Qt.rgba(c.r, c.g, c.b, opacity);
    }
}
