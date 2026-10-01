import QtQuick
import "../../Config"
import "../../Services"

/**
 * PlasmaApplets - The KDE Plasma applets set in config (bar.plasmaApplets), in that order; only where the
 * compositor backend can host them.
 */
Grid {
    id: root

    property int level: 0
    // The buttons whose applet loaded; one that failed is hidden
    readonly property var shown: {
        const buttons = [];
        for (let i = 0; i < applets.count; i++)
            if (applets.itemAt(i)?.loaded)
                buttons.push(applets.itemAt(i));
        return buttons;
    }

    function lengthAt(level) {
        return shown.reduce((total, button) => total + button.lengthAt(level), 0) + spacing * Math.max(0, shown.length - 1);
    }

    visible: shown.length > 0
    columns: BarLayout.vertical ? 1 : Math.max(1, shown.length)
    spacing: 2

    Repeater {
        id: applets

        model: Compositor.appletHostSource ? Config.options.bar.plasmaApplets : []

        PlasmaAppletButton {
            required property string modelData

            applet: modelData
            level: root.level
        }
    }
}
