import QtQuick
import "../../theme"
import "../../widgets"

// Hyprland logo pill at the start (left side) of the bar. Clicking toggles
// the session/power popup (PowerMenuPopup — lock / restart / power off,
// with an inline "About" row). Uses the Nerd Font glyph "nf-linux-hyprland"
// (same approach as the legacy shell).
Pill {
    id: root

    width: logo.width + Theme.pillPaddingH

    // Popup attached by shell.qml; clicks toggle it (the popup owns all
    // power/session actions and the About entry).
    property var popup: null

    Text {
        id: logo

        anchors.centerIn: parent
        text: "\uf359" // nf-linux-hyprland
        color: Theme.accent
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        font.pixelSize: Theme.fontSize
    }

    // Click toggles the power/session popup; hover: pointing hand cursor
    // (same interaction pattern as the Network/Bluetooth pills).
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.popup)
                root.popup.toggle();
        }
    }
}
