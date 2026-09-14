import QtQuick
import "../../theme"
import "../../widgets"

// Static Hyprland logo shown at the start (left side) of the bar.
// Visual only: no click handler. Uses the Nerd Font glyph
// "nf-linux-hyprland" (same approach as the legacy shell).
Pill {
    id: root

    width: logo.width + Theme.pillPaddingH

    Text {
        id: logo

        anchors.centerIn: parent
        text: "\uf359" // nf-linux-hyprland
        color: Theme.accent
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        font.pixelSize: Theme.fontSize
    }
}