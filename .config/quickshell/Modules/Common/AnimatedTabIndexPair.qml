import QtQuick

/**
 * AnimatedTabIndexPair - Dual-speed animation model
 *
 * Provides two animated indices that track the same index value
 * but with different animation speeds, creating a smooth elastic
 * "rubber-band" transition effect.
 *
 * - idx1 is the "leading" indicator (fast, 100ms)
 * - idx2 is the "following" indicator (slow, 300ms)
 */
QtObject {
    id: root
    required property int index

    property real idx1: index
    property real idx2: index
    property int idx1Duration: 100
    property int idx2Duration: 300

    Behavior on idx1 {
        NumberAnimation {
            duration: root.idx1Duration
            easing.type: Easing.OutSine
        }
    }

    Behavior on idx2 {
        NumberAnimation {
            duration: root.idx2Duration
            easing.type: Easing.OutSine
        }
    }
}
