import Quickshell
import QtQuick
import "../../theme"
import "../../widgets"

// Clock pill. Container visuals live in Pill; content here.
Pill {
    id: root

    width: clockText.width + Theme.pillPaddingH

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    Text {
        id: clockText

        anchors.centerIn: parent
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        color: Theme.accent

        text: Qt.formatDateTime(systemClock.date, "  hh:mmAP")
    }
}
