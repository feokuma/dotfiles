import Quickshell
import QtQuick
import "components/bar"
import "theme"

ShellRoot {
    PanelWindow {
        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
        }

        // Bar height and margin live in Theme (theme/Theme.qml).
        implicitHeight: Theme.barHeight

        Workspaces {
            anchors {
                left: parent.left
                leftMargin: Theme.barMargin
                verticalCenter: parent.verticalCenter
            }
        }

        Clock {
            anchors.centerIn: parent
        }

        Battery {
            anchors {
                right: parent.right
                rightMargin: Theme.barMargin
                verticalCenter: parent.verticalCenter
            }
        }
    }
}
