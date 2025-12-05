import QtQuick
import QtQuick.Layouts
import "../../Config"
import "../../Components"
import "../../Services"
import "../../Utils"

Item {
    id: root

    implicitWidth: sidebarBackground.implicitWidth + Theme.elevationMargin * 2
    implicitHeight: sidebarBackground.implicitHeight + Theme.elevationMargin * 2

    Rectangle {
        id: sidebarBackground
        anchors.fill: parent
        anchors.margins: Theme.elevationMargin

        color: Theme.alpha(Theme.colLayer0, 0.95)
        radius: Theme.radiusBase
        border.width: 1
        border.color: Theme.colLayer2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingLarge

            // Quick Sliders Section
            QuickSliders {
                Layout.fillWidth: true
            }

            // Tabbed Section (Volume Mixer, etc.)
            TabbedSection {
                Layout.fillWidth: true
            }

            // Quick Toggles Section
            QuickToggles {
                Layout.fillWidth: true
            }

            // Spacer to push everything to top
            Item {
                Layout.fillHeight: true
            }
        }

        Component.onCompleted: {
            Logger.info("Content loaded");
        }
    }
}
