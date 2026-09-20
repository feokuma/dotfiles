import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../../theme"
import "../../widgets"

// Session/power popup: lock screen, reboot, power off. Opened by clicking
// the Hyprland logo pill on the left of the bar.
//
// Container mirrors BluetoothPopup, but anchored to the bar's LEFT side
// (under the logo). Safety model: Reboot/Power off require an inline
// second-click confirmation ("Click again to confirm") managed by a single
// root `armedAction` state; the 3s auto-disarm Timer prevents accidental
// confirmations from a later visit. Lock is non-destructive, so a single
// click runs it. Every action closes the popup after dispatch.
// setsid detaches the child (hyprlock especially: it must outlive this
// shell across reload/restart, same rationale as the bluetoothctl spawn).
PopupBase {
    id: root

    // Which destructive action is armed for confirmation ("" = none).
    property string armedAction: ""
    // Native about window attached by shell.qml (AboutWindow.qml).
    property var aboutWindow: null

    readonly property var actions: [
        {
            key: "lock",
            label: "Lock screen",
            glyph: "󰌾",
            confirm: false
        },
        {
            key: "reboot",
            label: "Restart",
            glyph: "󰜉",
            confirm: true
        },
        {
            key: "poweroff",
            label: "Power off",
            glyph: "󰐥",
            confirm: true
        }
    ]

    Process {
        id: lockProc
        command: ["setsid", "hyprlock"]
        running: false
    }

    Process {
        id: rebootProc
        command: ["setsid", "systemctl", "reboot"]
        running: false
    }

    // "About": opens the native Quickshell about window (AboutWindow.qml),
    // attached by shell.qml. The popup closes so the click never lingers.
    Process {
        id: poweroffProc
        command: ["setsid", "systemctl", "poweroff"]
        running: false
    }

    // Second click within the window executes; else disarm.
    Timer {
        id: disarmTimer
        interval: 3000
        running: false
        onTriggered: root.armedAction = ""
    }

    function run(key: string) {
        if (key === "lock")
            lockProc.running = true;
        else if (key === "reboot")
            rebootProc.running = true;
        else if (key === "poweroff")
            poweroffProc.running = true;
        armedAction = "";
        close();
    }

    function requestAction(key: string, needsConfirm: bool) {
        if (!needsConfirm) {
            run(key);
            return;
        }
        if (armedAction === key) {
            run(key);
        } else {
            armedAction = key;
            disarmTimer.restart();
        }
    }

    onPopupClosed: armedAction = ""

    visible: root.isOpen
    color: "transparent"
    margins.top: Theme.barHeight + Theme.popupBarGap

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:powermenu-popup"

    // Fullscreen click-outside catcher; the card sits on top of it.
    MouseArea {
        anchors.fill: parent
        onPressed: root.close()
    }

    Rectangle {
        id: panel

        anchors {
            top: parent.top
            left: parent.left
            leftMargin: Theme.barMargin
        }
        width: Theme.popupWidth
        height: contentColumn.implicitHeight
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

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            topPadding: Theme.popupPadding
            bottomPadding: Theme.popupPadding
            leftPadding: Theme.popupPadding
            rightPadding: Theme.popupPadding
            spacing: 6

            Item {
                id: headerRow

                width: contentColumn.width - contentColumn.leftPadding - contentColumn.rightPadding
                height: Theme.popupRowHeight

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Session"
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    color: Theme.textMuted
                }
            }

            Repeater {
                model: root.actions

                delegate: PowerActionRow {
                    action: modelData
                }
            }
        }
    }

    component PowerActionRow: Item {
        id: row

        property var action: null

        readonly property bool armed: root.armedAction === action.key

        width: headerRow.width
        height: visible ? Theme.popupRowHeight : 0

        Rectangle {
            id: hoverRect

            anchors.fill: parent
            radius: Theme.pillRadius
            color: row.action.confirm && row.armed ? Theme.warning : Theme.highlight
            opacity: hoverArea.containsMouse || row.armed ? (row.armed ? 0.18 : 0.12) : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animFast
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Theme.animFast
                }
            }
        }

        // Glyph. Codepoints verified against the installed font's glyph
        // table: md-lock U+F033E, md-restart U+F0709, md-power U+F0425.
        Text {
            id: iconSlot

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            leftPadding: 10
            width: 24
            text: row.action.glyph
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 4
            font.bold: Theme.fontBold
            color: row.armed ? Theme.warning : Theme.text
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: iconSlot.right
            anchors.leftMargin: 10
            text: row.action.label
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: row.armed ? Theme.warning : Theme.text
        }

        // Armed hint replaces the (unused) status column on destructive rows.
        Text {
            visible: row.armed
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 10
            text: "Click again"
            font.pixelSize: Theme.fontSize - 1
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: Theme.warning
        }

        MouseArea {
            id: hoverArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.requestAction(row.action.key, row.action.confirm)
        }
    }
}
