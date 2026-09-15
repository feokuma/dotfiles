import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../../theme"

// Notification daemon + popup overlay.
//
// Lifecycle: the server emits notifications; setting `tracked = true`
// retains them. Expiry (timer inside Card for normal urgency) and explicit
// dismissal remove them from trackedNotifications, and the window shrinks
// back via reactive bindings.
//
// This is an overlay: exclusiveZone 0 so it does not reserve desktop space.
// It inherits ShellRoot's default screen like the bar; per-monitor hosts
// are deferred until a real multi-monitor strategy exists.
Item {
    id: root

    NotificationServer {
        id: server

        actionsSupported: true
        keepOnReload: false // suppress duplicate re-emission on reload churn

        onNotification: notification => {
            notification.tracked = true;
        }
    }

    PanelWindow {
        id: popupWindow

        implicitWidth: Theme.notificationWidth
        implicitHeight: stack.implicitHeight
        visible: server.trackedNotifications.values.length > 0
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
                model: server.trackedNotifications

                Card {
                    required property var modelData

                    notification: modelData
                }
            }
        }
    }
}
