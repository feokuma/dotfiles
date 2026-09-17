import Quickshell
import QtQuick
import "../theme"

// Reusable hover hint: a tiny click-through tooltip shown below a bar item
// while the consumer's hover state is true. PopupWindow (not an overlay
// PanelWindow) so it sizes freely to its content and follows the anchored item
// across window layout changes.
//
// Usage (inside any bar component next to the hovered item):
//   HoverHint {
//       target: someItem          // Item living in a window
//       text: hoverArea.containsMouse ? "foo" : ""
//       accent: Theme.accent
//   }
//
// visibility: derives from `text` — empty text hides the window, so the
// consumer only needs to switch the string.
PopupWindow {
    id: root

    // Item the hint is anchored below. Its window is resolved through
    // anchor.item, so the popup follows across reloads/screens.
    property Item target
    property string text
    property color accent: Theme.accent

    // Inner padding between the card and the text. Defaults to the shell's
    // standard hint spacing; consumers may override per-use.
    property real paddingHorizontal: 10
    property real paddingVertical: 4

    color: "transparent"
    visible: root.text.length > 0 && root.target

    // Fully click-through: an empty mask Region means this window never
    // takes input (same trick as the popups' overlay catcher inverse).
    mask: Region {}

    anchor {
        item: root.target

        // Anchor to the item's bottom edge, opening downwards.
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: 6
        // Slide out of the way when it would leave the screen.
        adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    }

    // Content-driven sizing: label → bubble implicit size → window size.
    implicitWidth: bubble.implicitWidth + 24
    implicitHeight: bubble.implicitHeight + 14

    Rectangle {
        id: bubble

        implicitWidth: label.implicitWidth + root.paddingHorizontal * 2
        implicitHeight: label.implicitHeight + root.paddingVertical * 2

        anchors.centerIn: parent
        radius: height / 2
        color: Theme.crust
        border.width: 1
        border.color: root.accent

        Text {
            id: label

            anchors.centerIn: parent
            text: root.text
            font.pixelSize: Theme.fontSize - 1
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: Theme.text
        }
    }
}
