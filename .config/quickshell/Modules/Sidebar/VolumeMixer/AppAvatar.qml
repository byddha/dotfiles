import QtQuick
import Quickshell
import "../../../Config"
import "../../../Components"
import "../../../Services"

// Real app icon (and `entry` for its real name) from the app's .desktop entry; the name's initial when there is none.
// PipeWire's application.icon-name is often missing or wrong (Vesktop reports Chromium): try the portal app id, then the binary, then the name.
Rectangle {
    id: root

    property var node: null

    readonly property var props: node?.properties ?? {}
    // Wine runs every game as wine(64)-preloader, so the binary says nothing there
    readonly property string binary: {
        const bin = props["application.process.binary"] ?? "";
        return /^wine(64)?(-preloader)?$/.test(bin) ? "" : bin.replace(/[.-]bin$/, "");
    }
    readonly property string name: (props["application.name"] ?? "").replace(/\.exe$/i, "")
    readonly property var entry: {
        const appId = props["pipewire.access.portal.app_id"] ?? "";
        return (appId && DesktopEntries.byId(appId)) || (binary && DesktopEntries.heuristicLookup(binary)) || (name && DesktopEntries.heuristicLookup(name)) || null;
    }
    readonly property string iconSource: AppIcons.iconForEntry(entry)

    implicitWidth: 32
    implicitHeight: 32
    radius: 16
    color: icon.status === Image.Ready ? "transparent" : Theme.secondaryContainer

    Image {
        id: icon
        anchors.fill: parent
        source: root.iconSource
        sourceSize.width: 64
        sourceSize.height: 64
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: status === Image.Ready
    }

    StyledText {
        anchors.centerIn: parent
        visible: icon.status !== Image.Ready
        text: (root.name || root.binary || "?").charAt(0).toUpperCase()
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        color: Theme.secondaryContainerText
    }
}
