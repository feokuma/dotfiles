//@ pragma UseQApplication
// Required by SystemTrayItem.display() / native tray menus — needs a full
// quickshell restart (not just file-watch reload) to take effect.
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
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

            HyprlandLogo {}

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

    Notifications {}

    IpcHandler {
        target: "launcher"

        function toggleLauncher() {
            launcher.toggle();
        }
    }
}
