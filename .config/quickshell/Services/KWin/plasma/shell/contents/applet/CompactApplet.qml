import QtQuick
import org.kde.plasma.plasmoid

// Holds the compact representation; the full one is left alone, PlasmoidHost hands it to the shell's own popup
Item {
    id: root

    anchors.fill: parent

    property Item fullRepresentation
    property Item compactRepresentation
    property Item expandedFeedback
    property PlasmoidItem plasmoidItem

    onCompactRepresentationChanged: {
        if (!compactRepresentation)
            return;
        compactRepresentation.parent = root;
        compactRepresentation.anchors.fill = root;
        compactRepresentation.visible = true;
    }
}
