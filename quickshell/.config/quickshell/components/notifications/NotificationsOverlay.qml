import QtQuick
import Quickshell
import "../../theme"

// Per-screen notification popup overlay.
//
// Lifecycle: the shared NotificationService singleton owns the daemon and the
// tracked list; expiry (timer inside Card for normal urgency) and explicit
// dismissal remove entries, and the window shrinks back via reactive bindings.
//
// This is an overlay: exclusiveZone 0 so it does not reserve desktop space.
// One instance is declared per screen (ScreenShell/Variants); `screen` is
// forwarded to the inner window instead of assuming the default screen.
Item {
    id: root

    // NotificationService.server — shared, single notification daemon.
    required property var server

    // Screen this overlay appears on (assigned by the per-screen host).
    property var screen

    PanelWindow {
        id: popupWindow

        screen: root.screen

        implicitWidth: Theme.notificationWidth
        implicitHeight: stack.implicitHeight
        visible: root.server
            ? root.server.trackedNotifications.values.length > 0
            : false
        color: "transparent"

        // Overlay window: do not reserve desktop space.
        exclusiveZone: 0
        anchors {
            top: true
            right: true
        }
        margins {
            top: Theme.notificationTopGap
            right: Theme.barMargin
        }

        // Cards stack; the window itself is visible only while empty.
        Column {
            id: stack

            anchors {
                top: parent.top
                right: parent.right
            }
            spacing: Theme.notificationStackSpacing

            Repeater {
                model: root.server ? root.server.trackedNotifications : []

                Card {
                    required property var modelData

                    notification: modelData
                }
            }
        }
    }
}
