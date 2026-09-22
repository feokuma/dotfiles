import Quickshell
import QtQuick
import "../../theme"
import "../../widgets"

// Clock pill. Container visuals live in Pill; content here.
Pill {
    id: root

    width: clockText.width + Theme.pillPaddingH

    // Calendar popup attached by shell.qml; clicks toggle it (see Network.qml).
    property var popup: null

    MouseArea {
        id: hoverArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.popup)
                root.popup.toggle();
        }
    }

    // Full (locale) date shown as a tooltip while hovering, same pattern
    // as Network.qml's HoverHint.
    HoverHint {
        target: root
        text: hoverArea.containsMouse
            ? Qt.formatDate(systemClock.date, "dddd, d MMMM yyyy") : ""
        accent: Theme.peach
    }

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
        color: Theme.peach

        text: Qt.formatDateTime(systemClock.date, "  hh:mmAP")
    }
}
