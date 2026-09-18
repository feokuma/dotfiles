import QtQuick
import QtQuick.Controls
import "../theme"

// Themed text button built on QtQuick.Controls Button, shared by the bar
// popups (scan/cancel/connect/forget). The popup layer has no global Qt
// style, so look & feel lives here in background/contentItem and any Theme
// tweak applies to every consumer at once.
//
// Consumers may still override per-instance bits (padding, font size,
// hoverEnabled) — see the Forget button in NetworkPopup.
Button {
    id: control

    // Accent styling (border + label) for toggle/busy states, like Scan
    // while scanning or Connect while connecting.
    property bool active: false

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize - 1
    font.bold: Theme.fontBold
    leftPadding: 12
    rightPadding: 12

    implicitHeight: 36

    background: Rectangle {
        radius: Theme.pillRadius
        color: Theme.crust
        border.width: 1
        // Muted by default, text-colored on hover/focus, accent while active.
        border.color: control.active ? Theme.accent : control.enabled && (control.hovered || control.visualFocus) ? Theme.text : Theme.textMuted
        opacity: control.enabled ? 1.0 : 0.5

        Behavior on border.color {
            NumberAnimation {
                duration: Theme.animFast
            }
        }
    }

    contentItem: Text {
        text: control.text
        font: control.font
        color: control.active ? Theme.accent : Theme.text
        verticalAlignment: Text.AlignVCenter
    }
}
