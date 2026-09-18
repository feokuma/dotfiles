import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../services"
import "../../theme"
import "../../widgets"

// Power-profiles popup: lists the profiles exposed by power-profiles-daemon
// and lets the user switch the active one. Opened by clicking the Battery
// pill. Reads/writes go through the PowerProfileService singleton (busctl
// under the hood), so nothing here talks to D-Bus directly.
// Visual pattern mirrors AudioPopup (fullscreen invisible overlay card +
// collapsible dropdown).
PopupBase {
    id: root

    visible: root.isOpen
    color: "transparent"
    margins.top: Theme.barHeight + Theme.popupBarGap

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:powerprofiles-popup"

    // Fullscreen click-outside catcher; the card sits on top of it.
    MouseArea {
        anchors.fill: parent
        onPressed: root.close()
    }

    Rectangle {
        id: panel

        anchors {
            top: parent.top
            right: parent.right
            rightMargin: Theme.barMargin
        }
        width: Theme.popupWidth
        height: contentColumn.implicitHeight + contentColumn.anchors.margins * 2
        radius: Theme.pillRadius
        color: Theme.pillBackground
        border.width: 1
        border.color: Theme.highlight
        clip: true

        opacity: root.isOpen ? 1 : 0

        readonly property int appearDuration: Theme.animFast

        transform: Translate {
            y: root.isOpen ? 0 : -14

            Behavior on y {
                NumberAnimation {
                    duration: panel.appearDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: panel.appearDuration
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: contentColumn

            anchors.fill: parent
            anchors.margins: 2
            topPadding: Theme.popupPadding
            bottomPadding: Theme.popupPadding
            leftPadding: Theme.popupPadding
            rightPadding: Theme.popupPadding
            spacing: 10

            Text {
                text: "Power"
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                color: Theme.textMuted
            }

            ProfileDropdown {
                width: contentColumn.width - contentColumn.leftPadding - contentColumn.rightPadding
                nodes: PowerProfileService.profiles
                currentName: PowerProfileService.profile
                onSelect: profile => {
                    PowerProfileService.setProfile(profile);
                    root.close();
                }
            }
        }
    }

    // Collapsible profile list; follow AudioPopup's DeviceDropdown geometry.
    component ProfileDropdown: Column {
        id: dd

        property var nodes: []
        property string currentName: ""
        property bool expanded: false
        signal select(string profile)

        spacing: 2

        // Reset to collapsed whenever the popup is reopened, so the card
        // always starts with just the header row visible.
        property bool popupOpen: root.isOpen
        onPopupOpenChanged: {
            if (popupOpen)
                expanded = false;
        }

        // Capitalized display helper, used by header text and rows alike.
        function capitalize(name: string): string {
            return name.length > 0 ? name.charAt(0).toUpperCase() + name.slice(1) : "…";
        }

        Item {
            id: header

            width: dd.width
            height: Theme.popupRowHeight

            Rectangle {
                anchors.fill: parent
                radius: Theme.pillRadius
                color: Theme.highlight
                opacity: headerArea.containsMouse ? 0.12 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animFast
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                // Muted so the node name reads as the payload, like
                // DeviceDropdown's "Output device — ..." header text.
                text: `Profile — ${dd.nodes.includes(dd.currentName) ? dd.capitalize(dd.currentName) : "…"}`
                elide: Text.ElideRight
                width: parent.width - chevron.width - 24
                font.pixelSize: Theme.fontSize - Theme.popupSectionFontDelta
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                color: Theme.textMuted
            }

            Text {
                id: chevron

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 8
                text: dd.expanded ? "▾" : "▸"
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                color: Theme.textMuted
            }

            MouseArea {
                id: headerArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dd.expanded = !dd.expanded
            }
        }

        // Animated expand: clipping reveals the list instead of tearing it
        // out of layout (height 0 when collapsed keeps Column spacing sane).
        Rectangle {
            id: listClip

            width: dd.width
            height: dd.expanded ? Math.min(listCol.height, 180) : 0
            radius: Theme.pillRadius
            color: Theme.crust
            border.width: 1
            border.color: Theme.accent
            clip: true

            Behavior on height {
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: Easing.OutCubic
                }
            }

            Column {
                id: listCol

                width: parent.width
                topPadding: 4
                bottomPadding: 4
                spacing: 0

                Text {
                    // Friendly empty state while the daemon is not answering.
                    visible: dd.nodes.length === 0
                    text: "No profiles available"
                    font.pixelSize: Theme.fontSize - 1
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                Repeater {
                    model: dd.nodes

                    delegate: ProfileRow {
                        required property string modelData
                        profileName: modelData
                        accent: Theme.accent
                        active: modelData === dd.currentName
                        onSelect: profile => dd.select(profile)
                    }
                }
            }
        }
    }

    // One profile row: glyph + name; a check mark on the active one.
    component ProfileRow: Item {
        id: row

        required property string profileName
        property color accent
        property bool active
        signal select(string profile)

        width: parent ? parent.width : 0
        height: Theme.popupRowHeight - 6

        Rectangle {
            anchors.fill: parent
            radius: Theme.pillRadius
            color: Theme.highlight
            opacity: rowArea.containsMouse ? 0.18 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animFast
                }
            }
        }

        Text {
            id: iconSlot

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            width: 24
            text: PowerProfileService.glyph(row.profileName)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 4
            font.bold: Theme.fontBold
            color: row.active ? row.accent : Theme.text
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: iconSlot.right
            anchors.leftMargin: 10
            anchors.right: check.left
            anchors.rightMargin: 8
            text: row.profileName.charAt(0).toUpperCase() + row.profileName.slice(1)
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize - 1
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: row.active ? row.accent : Theme.text
        }

        Text {
            id: check

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 8
            visible: row.active
            text: "✓"
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: row.accent
        }

        MouseArea {
            id: rowArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.select(row.profileName)
        }
    }
}
