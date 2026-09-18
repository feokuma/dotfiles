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

                readonly property int focusMarkWidth: 16

                required property var modelData

                readonly property bool isFocused: modelData.focused ?? false
                // Workspace urgency: a client on this workspace requested
                // attention (e.g. tab opened, DM received). Cleared on focus.
                readonly property bool isUrgent: modelData.urgent ?? false

                width: label.width + focusMarkWidth
                // Inner highlight keeps one vertical padding of breathing
                // room inside the fixed pill (38 - 8 = 30).
                height: Theme.pillHeight - Theme.pillPaddingV
                radius: Theme.pillRadius
                color: {
                    if (delegateRoot.isUrgent)
                        return Theme.success;
                    if (delegateRoot.isFocused)
                        return Theme.highlight;
                    return "transparent";
                }

                Text {
                    id: label

                    anchors.centerIn: parent
                    text: delegateRoot.modelData.id
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    color: delegateRoot.isFocused || delegateRoot.isUrgent ? Theme.crust : Theme.text
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: delegateRoot.modelData.activate()
                }
            }
        }
    }
}
