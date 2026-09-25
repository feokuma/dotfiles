import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../about"
import "../bar"
import "../launcher"
import "../notifications"
import "../../services"
import "../../theme"
import "../../utils"

// Per-screen shell host, instantiated once for every connected screen by
// shell.qml (Variants model: Quickshell.screens).
//
// Everything visual that belongs to a monitor lives here: the bar, its
// popups, the launcher, the About window and the notification overlay.
// Each window gets `screen: modelData` so the whole shell follows the
// monitor it was created for; adding/removing screens creates/destroys
// instances reactively.
//
// App-wide singletons (NotificationService, PopupManager, Theme) stay
// outside — PopupManager remains cross-screen so only ONE popup is open
// in the whole session at a time. The shared notification daemon is owned
// by the NotificationService singleton; this file only hosts its overlay.
Scope {
    id: shell

    // Populated by Variants with the ShellScreen this instance serves.
    property var modelData

    // Routed by shell.qml IPC helpers (focused-screen toggle/close).
    readonly property alias launcher: launcher
    readonly property alias calendarPopup: calendarPopup
    readonly property alias colorsPopup: colorsPopup

    // Close an open popup/util window on this screen (from the global Esc
    // IPC in shell.qml). Only one popup is open session-wide at a time, so
    // this also clears popups opened on other screens.
    function closePopups(): void {
        if (PopupManager.current !== null)
            PopupManager.current.close();
        if (aboutWindow.isOpen)
            aboutWindow.close();
    }

    PanelWindow {
        id: barWindow

        screen: shell.modelData
        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
        }

        // Bar height and margin live in Theme (theme/Theme.qml).
        implicitHeight: Theme.barHeight

        // The popups' fullscreen click-outside catcher starts below the bar
        // (margins.top), so bar clicks bypass it. This bar-level catcher,
        // declared FIRST (under the pills' own MouseAreas), closes the open
        // popup when the bar's free area is clicked; clicking a pill still
        // goes to the pill (toggle/open) instead.
        MouseArea {
            anchors.fill: parent
            enabled: PopupManager.current !== null
            onClicked: PopupManager.current.close()
        }

        Row {
            anchors {
                left: parent.left
                leftMargin: Theme.barMargin
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.itemSpacing

            HyprlandLogo {
                id: hyprlandLogo
                Layout.preferredWidth: width
                popup: powerMenuPopup
            }

            Workspaces {}
        }

        Clock {
            id: clock
            anchors.centerIn: parent
            popup: calendarPopup
        }

        RowLayout {
            anchors {
                right: parent.right
                rightMargin: Theme.barMargin
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.itemSpacing

            Brightness {}

            Tray {
                parentWindow: barWindow
                Layout.preferredWidth: width
            }

            Network {
                id: network
                Layout.preferredWidth: width
                popup: networkPopup
            }

            Bluetooth {
                id: bluetooth
                Layout.preferredWidth: width
                popup: bluetoothPopup
            }

            Audio {
                id: audio
                popup: audioPopup
            }

            Battery {
                popup: powerProfilesPopup
            }
        }
    }

    PowerProfilesPopup {
        id: powerProfilesPopup
        screen: shell.modelData
    }

    AudioPopup {
        id: audioPopup
        audioRef: audio
        screen: shell.modelData
    }

    BluetoothPopup {
        id: bluetoothPopup
        screen: shell.modelData
    }

    NetworkPopup {
        id: networkPopup
        screen: shell.modelData
    }

    CalendarPopup {
        id: calendarPopup
        screen: shell.modelData
    }

    Launcher {
        id: launcher
        screen: shell.modelData
    }

    // Floating, centered "About this system" window, opened by this screen's
    // power menu's About row.
    AboutWindow {
        id: aboutWindow
        screen: shell.modelData
    }

    PowerMenuPopup {
        id: powerMenuPopup
        screen: shell.modelData
        aboutWindow: aboutWindow
    }

    // Recent picked colors + Pick Color action. Dot-comma feedback side:
    // after a successful pick (any entry point: keybind, popup button,
    // future launcher action) the popup reopens here with the new color
    // highlighted — visual feedback without extra notification plumbing.
    ColorsPopup {
        id: colorsPopup
        screen: shell.modelData
    }

    Connections {
        target: ColorService

        function onColorPicked(hex) {
            // Only the focused screen's popup opens; the others stay idle.
            if (shell.modelData.name !== (Hyprland.focusedMonitor?.name ?? ""))
                return;
            colorsPopup.openFor(hex);
        }
    }

    NotificationsOverlay {
        screen: shell.modelData
        server: NotificationService.server
    }
}
