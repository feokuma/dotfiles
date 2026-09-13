import Quickshell.Hyprland
import QtQuick

// Minimal workspaces pill. Visual values mirror Clock.qml
// (black pill, radius 9, 0.7 opacity) as a starting point only;
// TODO(theme): extract shared literals when Theme.qml is created.
Item {
    id: root

    implicitWidth: background.width
    implicitHeight: background.height

    Rectangle {
        id: background

        color: "black"
        radius: 9
        opacity: 0.7

        width: row.width + 16
        height: row.height + 8
    }

    Row {
        id: row

        anchors.centerIn: background
        spacing: 4

        Repeater {
            // Filter at the model level (named workspaces have id < 0)
            // so hidden items never leave residual spacing in the Row.
            // Hyprland.workspaces is reactive via socket2: no polling.
            model: Hyprland.workspaces.values.filter(function (ws) {
                return ws.id > 0;
            })

            delegate: Rectangle {
                id: delegateRoot

                required property var modelData

                readonly property bool isFocused: modelData.focused ?? false

                width: label.width + 16
                height: label.height + 8
                radius: 9
                color: delegateRoot.isFocused ? "#fab387" : "transparent"

                Text {
                    id: label

                    anchors.centerIn: parent
                    text: delegateRoot.modelData.id
                    font.pixelSize: 15
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    color: delegateRoot.isFocused ? "black" : "#cdd6f4"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: delegateRoot.modelData.activate()
                }
            }
        }
    }
}
