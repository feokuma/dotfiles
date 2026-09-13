import Quickshell
import QtQuick

// Minimal clock pill. Visual values start from dotfiles-legacy
// (black pill, radius 9, 0.7 opacity) as a starting point only;
// no theme abstraction yet — extract when a second component reuses them.
Item {
    id: root

    implicitWidth: background.width
    implicitHeight: background.height

    Rectangle {
        id: background

        color: "black"
        radius: 9
        opacity: 0.7

        height: clockText.height + 16
        width: clockText.width + 16
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    Text {
        id: clockText

        anchors.centerIn: background
        font.pixelSize: 15
        font.family: "JetBrainsMono Nerd Font"
        font.bold: true
        color: "#fab387"

        text: Qt.formatDateTime(systemClock.date, "  hh:mm AP")
    }
}
