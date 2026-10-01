import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import "../../Config"
import "../../Services"
import "../../Utils"

/**
 * PlasmaAppletButton - A KDE Plasma applet in the bar: its own compact view, and its full view in a popout.
 *
 * The applet decides when it is expanded (a click on its compact view); the popout follows, and closing the
 * popout collapses the applet.
 */
BarItem {
    id: root

    required property string applet
    readonly property var host: loader.item

    // Only an applet that loaded takes room in the bar
    readonly property bool loaded: host !== null && host.error === ""

    visible: loaded
    iconOnly: true
    highlighted: popout.visible
    tooltipTitle: popout.visible ? "" : host?.toolTipMainText || host?.title || ""
    tooltipDetail: popout.visible ? "" : host?.toolTipSubText ?? ""

    Item {
        implicitWidth: BarLayout.appIconSize
        implicitHeight: BarLayout.appIconSize

        Loader {
            id: loader

            anchors.fill: parent
            source: Compositor.appletHostSource
            onLoaded: {
                item.edge = Qt.binding(() => BarLayout.edge);
                item.applet = root.applet;
            }
            onStatusChanged: if (status === Loader.Error)
                Logger.warn(`Plasma applet ${root.applet}: no Bidshell.Plasma module; run ~/dotfiles/scripts/setup --only plasma and start qs with QML_IMPORT_PATH (PORT.md)`)
        }
    }

    Connections {
        target: root.host

        function onErrorChanged() {
            Logger.warn(`Plasma applet ${root.applet} could not be shown: ${root.host.error}`);
        }

        function onExpandedChanged() {
            if (root.host.expanded)
                popout.openFrom(root);
            else
                popout.hidePanel();
        }
    }

    property BarPopout popout: BarPopout {
        id: popout

        WlrLayershell.namespace: "bidshell:plasma-applet"
        padding: Theme.spacingBase

        onPanelClosed: if (root.host)
            root.host.expanded = false

        // The applet's full view, at the size it asks for
        Item {
            id: holder

            readonly property Item full: root.host?.fullRepresentation ?? null

            implicitWidth: full ? Math.max(full.Layout.minimumWidth, full.Layout.preferredWidth > 0 ? full.Layout.preferredWidth : full.implicitWidth) : 0
            implicitHeight: full ? Math.max(full.Layout.minimumHeight, full.Layout.preferredHeight > 0 ? full.Layout.preferredHeight : full.implicitHeight) : 0

            onFullChanged: {
                if (!full)
                    return;
                full.parent = holder;
                full.anchors.fill = holder;
                full.visible = true;
                // Plasma's heading frame is drawn for its own popup and overwrites our panel's colour with its transparency
                if (full.header?.background)
                    full.header.background.visible = false;
            }
        }
    }
}
