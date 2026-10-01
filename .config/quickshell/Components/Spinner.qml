import QtQuick
import "../Services"

Icon {
    id: root

    text: Lucide.loaderCircle

    RotationAnimator on rotation {
        from: 0
        to: 360
        duration: 1100
        loops: Animation.Infinite
        running: root.visible
    }
}
