//@ pragma UseQApplication
// Required by SystemTrayItem.display() / native tray menus — needs a full
// quickshell restart (not just file-watch reload) to take effect.
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "components/about"
import "components/bar"
import "components/launcher"
import "components/notifications"
import "theme"
import "utils"

ShellRoot {
    PanelWindow {
        id: barWindow

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
            anchors.centerIn: parent
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
    }

    AudioPopup {
        id: audioPopup
        audioRef: audio
    }

    BluetoothPopup {
        id: bluetoothPopup
    }

    NetworkPopup {
        id: networkPopup
    }

    Launcher {
        id: launcher
    }

    // Floating, centered "About this system" window, opened by the
    // power menu's About row.
    AboutWindow {
        id: aboutWindow
    }

    PowerMenuPopup {
        id: powerMenuPopup
        aboutWindow: aboutWindow
    }

    Notifications {}

    IpcHandler {
        target: "launcher"

        function toggleLauncher() {
            launcher.toggle();
        }
    }

    // Called by the non-consuming Esc bind (see keybindings.lua). Popups and
    // the About window take no keyboard focus, so Esc reaches the compositor
    // instead of them. No-op when nothing is open.
    IpcHandler {
        target: "popup"

        function closeActive() {
            if (PopupManager.current !== null)
                PopupManager.current.close();
            if (aboutWindow.isOpen)
                aboutWindow.close();
        }
    }
}
