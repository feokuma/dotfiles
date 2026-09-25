import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "../../services"
import "../../theme"
import "../../widgets"

// Color Picker popup: recent picked colors (hyprpicker via ColorService).
// Opened by the shell IPC after a pick (feedback for the newly captured
// color), and by a future bar pill / launcher action. Picking itself lives
// in ColorService (keybind/IPC), not here.
//
// Rewrites nothing of PopupBase: catcher, manager registration and the
// open/close/toggle contract are inherited; only appearance/local state here.
PopupBase {
    id: root

    // Row to visually mark as "just picked" (set by openFor, cleared on
    // close so a later manual open looks neutral).
    property string highlightedHex: ""

    // Open directly with feedback for a freshly picked color.
    function openFor(hex: string): void {
        root.highlightedHex = hex;
        root.open();
    }

    onPopupClosed: root.highlightedHex = ""

    visible: root.isOpen
    color: "transparent"
    margins.top: Theme.barHeight + Theme.popupBarGap

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:colors-popup"

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
        height: content.implicitHeight + content.anchors.margins * 2
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
            id: content

            anchors.fill: parent
            anchors.margins: 2
            topPadding: Theme.popupPadding
            bottomPadding: Theme.popupPadding
            leftPadding: Theme.popupPadding
            rightPadding: Theme.popupPadding
            spacing: 8

            readonly property real rowWidth: width - leftPadding - rightPadding

            Text {
                // Cosmetic header row anchors the popup semantics.
                text: "Color Picker"
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                color: Theme.textMuted
            }

            Repeater {
                model: ColorService.history

                delegate: Item {
                    id: row

                    width: content.rowWidth
                    height: Theme.popupRowHeight

                    // Post-copy feedback: flips the hover hint from "Copy"
                    // to a success-colored "Copied" for a beat, so the click
                    // confirms itself without a separate notification.
                    property bool justCopied: false

                    Timer {
                        id: copiedTimer

                        interval: 900
                        onTriggered: row.justCopied = false
                    }

                    readonly property bool highlighted: root.highlightedHex !== "" && root.highlightedHex === modelData

                    // Row hover bar (like the launcher rows): neutral
                    // highlight bar plus the RGB form shown while hovered.
                    // No persistent highlight: the accent ring below marks
                    // the just-picked row until the popup closes.
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.pillRadius
                        color: Theme.highlight
                        opacity: hoverArea.containsMouse ? 0.18 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animFast
                            }
                        }
                    }

                    // Whole-row click target: any point on the row copies.
                    // The children (swatch, texts) don't register mouse
                    // events, so they let clicks fall through to this.
                    MouseArea {
                        id: hoverArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ColorService.copy(modelData);
                            row.justCopied = true;
                            copiedTimer.restart();
                        }
                    }

                    Row {
                        anchors.fill: parent
                        leftPadding: 2
                        spacing: 10

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            radius: 5
                            color: modelData
                            border.width: 1
                            border.color: row.highlighted ? Theme.accent : Theme.textMuted
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            font.bold: Theme.fontBold
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ColorService.toRgb(modelData)
                            visible: hoverArea.containsMouse
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 5
                            font.bold: false
                        }
                    }

                    // "Copy" hover hint pinned to the row's right edge.
                    // Non-interactive on purpose: a hoverable Button here
                    // steals hover from the row MouseArea, making it flicker
                    // off exactly when the cursor reaches it. The whole row
                    // is the click target (MouseArea above); this label is
                    // just the affordance shown while hovering.
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        text: row.justCopied ? "Copied" : "Copy"
                        color: row.justCopied ? Theme.success : Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 4
                        font.bold: Theme.fontBold
                        opacity: hoverArea.containsMouse || row.justCopied ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animFast
                            }
                        }
                    }
                }
            }

            // Empty state, before the first pick.
            Text {
                visible: ColorService.history.length === 0
                text: "No colors yet"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }
}
