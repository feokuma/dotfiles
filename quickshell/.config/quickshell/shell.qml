import Quickshell
import QtQuick
import "components/bar"

ShellRoot {
    PanelWindow {
        color: "transparent"

        anchors {
            top: true
            left: true
            right: true
        }

        // Bar height. Easy to adjust later; keep in one place.
        implicitHeight: 42

        Workspaces {
            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
        }

        Clock {
            anchors.centerIn: parent
        }
    }
}
