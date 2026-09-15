//@ pragma UseQApplication
// Required by SystemTrayItem.display() / native tray menus — needs a full
// quickshell restart (not just file-watch reload) to take effect.
import Quickshell
import QtQuick
import QtQuick.Layouts
import "components/bar"
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
                Layout.preferredWidth: width
            }

            Bluetooth {
                Layout.preferredWidth: width
            }

            Audio {}

            Battery {}
        }
    }
}
