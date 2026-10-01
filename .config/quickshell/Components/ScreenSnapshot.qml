import QtQuick
import "../Services"

// One still frame of a screen, drawn by the compositor backend, with nothing else in it
Loader {
    id: root

    required property var screen
    readonly property bool hasContent: status === Loader.Ready && item.hasContent

    source: Compositor.screenSnapshotSource

    Binding {
        target: root.item
        property: "screen"
        value: root.screen
        when: root.status === Loader.Ready
    }
}
