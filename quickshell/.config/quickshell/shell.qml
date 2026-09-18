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
