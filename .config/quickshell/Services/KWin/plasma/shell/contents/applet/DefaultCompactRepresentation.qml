import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

// For applets without a compact representation of their own: their icon, which toggles the popup
Kirigami.Icon {
    property PlasmoidItem plasmoidItem

    source: Plasmoid.icon
    active: mouseArea.containsMouse

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => mouse.button === Qt.MiddleButton ? Plasmoid.secondaryActivated() : Plasmoid.activated()
    }
}
