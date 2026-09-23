pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Application-level notification service (single owner per process).
//
// Why a singleton: Quickshell should host exactly one notification daemon.
// Keeping the server here lets the per-screen overlays (NotificationsOverlay,
// one per monitor via ScreenShell/Variants) all read from the same
// trackedNotifications model without duplicating the daemon side.
Item {
    id: root

    NotificationServer {
        id: service

        actionsSupported: true
        keepOnReload: false // suppress duplicate re-emission on reload churn

        onNotification: notification => {
            notification.tracked = true;
        }
    }

    // Reactive list of retained notifications consumed by the per-screen
    // overlays (NotificationsOverlay binds `server` to this).
    readonly property var server: service
    readonly property var trackedNotifications: service.trackedNotifications
}
