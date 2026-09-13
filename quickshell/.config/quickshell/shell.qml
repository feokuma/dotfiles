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

        Clock {
            anchors.centerIn: parent
        }
    }
}
