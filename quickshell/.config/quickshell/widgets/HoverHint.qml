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

    // Desired visibility derived purely from the public API, so consumers keep
    // just setting `text`. The animated `shown` state lags behind this on the
    // way out (see below), decoupling "should be visible" from "window is up".
    readonly property bool wantVisible: root.text.length > 0 && !!root.target

    // Mapped-window state. Snaps on for entrance, held briefly on exit (see
    // holdTimer) so the fade-out is visible before the window truly hides.
    property bool shown: false

    // During the exit fade `text` is already empty, which would render an
    // empty bubble; keep the last non-empty string for the label so it fades
    // out with content. Reset only when fully hidden. Done imperatively on
    // purpose: a self-referencing binding reads as a QML binding loop and Qt
    // may break it, leaving lastText empty exactly when it is needed.
    property string lastText: ""
    onTextChanged: if (text.length > 0)
        lastText = text
    onShownChanged: if (!shown)
        lastText = ""

    // Entrance/exit timing, referenced by both the state transitions and the
    // exit-hold timer so they stay in lockstep. Fast matches the popups' motif.
    readonly property int enterDuration: Theme.animFast
    readonly property int exitDuration: Theme.animFast

    color: "transparent"

    // The window is mapped only while `shown` is true; `shown` survives the
    // fade-out window so the bubble animates, then the hold timer clears it,
    // guaranteeing no lingering (even if click-through) surface stays mapped.
    visible: root.shown

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

    onWantVisibleChanged: {
        if (wantVisible) {
            // Re-entering during an in-flight exit: cancel the hide and let the
            // entrance transition reverse from wherever the fade-out reached.
            holdTimer.stop();
            root.shown = true;
        } else if (root.shown) {
            // Keep the window alive just past the fade so the final frames
            // actually render; the extra stretch is transparent + click-through
            // (empty mask), so it is harmless.
            holdTimer.restart();
        }
    }

    Timer {
        id: holdTimer

        // Slightly longer than the exit transition to avoid clipping its last
        // frame; the padding is invisible (opacity already 0 by then).
        interval: root.exitDuration + 40
        onTriggered: root.shown = false
    }

    Rectangle {
        id: bubble

        implicitWidth: label.implicitWidth + root.paddingHorizontal * 2
        implicitHeight: label.implicitHeight + root.paddingVertical * 4

        anchors.centerIn: parent
        radius: Theme.pillRadius //height / 2
        color: Theme.crust
        border.width: 1
        border.color: root.accent

        // Base (shown) look; the "faded" state below overrides it.
        opacity: 1
        scale: 1

        states: State {
            name: "faded"

            // Driven by intent (wantVisible), not window visibility, so the
            // exit animation runs while the window is still mapped by `shown`.
            when: !root.wantVisible

            // Fade + a gentle shrink toward the anchored item reads as the
            // bubble "retreating" back into the bar rather than blinking off.
            PropertyChanges {
                target: bubble
                opacity: 0
                scale: 0.92
            }
        }

        // Direction-specific easing: one Transition per edge of the "faded"
        // state, since a plain Behavior can't differ between in and out.
        transitions: [
            Transition {
                from: "faded"
                to: "*"

                // Entrance: quick, decelerating pop-in.
                ParallelAnimation {
                    NumberAnimation {
                        target: bubble
                        property: "opacity"
                        duration: root.enterDuration
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: bubble
                        property: "scale"
                        duration: root.enterDuration
                        easing.type: Easing.OutCubic
                    }
                }
            },
            Transition {
                to: "faded"

                // Exit: ease-in so it lingers a beat, then leaves; matches the
                // holdTimer interval above.
                ParallelAnimation {
                    NumberAnimation {
                        target: bubble
                        property: "opacity"
                        duration: root.exitDuration
                        easing.type: Easing.InCubic
                    }
                    NumberAnimation {
                        target: bubble
                        property: "scale"
                        duration: root.exitDuration
                        easing.type: Easing.InCubic
                    }
                }
            }
        ]

        Text {
            id: label

            anchors.centerIn: parent
            text: root.text.length > 0 ? root.text : root.lastText
            font.pixelSize: Theme.fontSize - 1
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: Theme.text
        }
    }
}
