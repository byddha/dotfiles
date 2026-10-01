import QtQuick
import "../Services"

// One still frame of a window, drawn by the compositor backend; nothing where it has no previews
Loader {
    id: root

    required property string windowId
    readonly property bool hasContent: status === Loader.Ready && item.hasContent

    source: Compositor.windowPreviewSource

    Binding {
        target: root.item
        property: "windowId"
        value: root.windowId
        when: root.status === Loader.Ready
    }
}
