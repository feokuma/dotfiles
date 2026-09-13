import QtQuick
import "../theme"

// Shared pill container for bar widgets.
// Centralizes background, radius, opacity and fixed height, so a
// Theme adjustment applies to every pill at once.
//
// Content stays with the consumer: add children anchored to the Pill
// (e.g. anchors.centerIn: parent). Width also stays with the consumer:
// `width: <content>.width + Theme.pillPaddingH`.
Item {
    id: root

    implicitHeight: Theme.pillHeight

    Rectangle {
        anchors.fill: parent
        color: Theme.pillBackground
        radius: Theme.pillRadius
        opacity: Theme.pillOpacity
    }
}
