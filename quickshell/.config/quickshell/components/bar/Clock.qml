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
