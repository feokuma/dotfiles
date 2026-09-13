import Quickshell.Hyprland
import QtQuick
import "../../theme"
import "../../widgets"

// Workspaces pill. Container visuals live in Pill; content here.
Pill {
    id: root

    width: row.width + Theme.pillPaddingH

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Theme.itemSpacing

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

                width: label.width + Theme.pillPaddingH
                // Inner highlight keeps one vertical padding of breathing
                // room inside the fixed pill (36 - 8 = 28, as before).
                height: Theme.pillHeight - Theme.pillPaddingV
                radius: Theme.pillRadius
                color: delegateRoot.isFocused ? Theme.accent : "transparent"

                Text {
                    id: label

                    anchors.centerIn: parent
                    text: delegateRoot.modelData.id
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    color: delegateRoot.isFocused ? Theme.textOnAccent : Theme.text
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: delegateRoot.modelData.activate()
                }
            }
        }
    }
}
