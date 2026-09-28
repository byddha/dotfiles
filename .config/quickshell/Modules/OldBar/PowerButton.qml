import QtQuick
import "../../Services"
import "../../Components"
import "Popups"

BarPill {
    id: powerButton

    width: BarStyle.buttonSize
    onClicked: {
        if (powerButton.activePopup) {
            powerButton.activePopup.hidePanel();
        } else {
            powerButton.showPowerPopup();
        }
    }

    property var activePopup: null

    FocusGrab {
        id: focusGrab
        active: false
        windows: powerButton.activePopup ? [powerButton.activePopup] : []
        onCleared: {
            if (powerButton.activePopup) {
                powerButton.activePopup.hidePanel();
                powerButton.releaseFocus();
            }
        }
    }

    function setActivePopupAndGrabFocus(popupWindow) {
        powerButton.activePopup = popupWindow;
        focusGrab.active = Compositor.useHyprlandFocusGrab;
    }

    function releaseFocus() {
        focusGrab.active = false;
        powerButton.activePopup = null;
        popupLoader.active = false;
    }

    function showPowerPopup() {
        popupLoader.active = true;
    }

    Loader {
        id: popupLoader
        active: false

        sourceComponent: PowerPopup {
            Component.onCompleted: {
                showPanel(powerButton);
            }

            onPanelOpened: window => powerButton.setActivePopupAndGrabFocus(window)
            onPanelClosed: powerButton.releaseFocus()
        }
    }

    Text {
        anchors.centerIn: parent
        text: Icons.power
        font.family: BarStyle.iconFont
        font.pixelSize: BarStyle.iconSize
        color: BarStyle.iconColor
    }
}
