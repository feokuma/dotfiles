import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../theme"

// Floating "Keybindings" cheatsheet window, centered on the screen.
//
// Behavior mirrors AboutWindow.qml: opened from the PowerMenuPopup
// "Keybindings" row (shell/ScreenShell attaches it as
// `PowerMenuPopup.cheatsheetWindow`), not a bar popup and outside
// PopupManager on purpose (it may coexist with one being open), fullscreen
// transparent PanelWindow with a click-outside catcher, card anchored to
// the exact center — resolution/scale independent.
//
// Data policy: the list is a STATIC declarative model kept in sync with
// hypr/.config/hypr/keybindings.lua by hand. Parsing the Lua config at
// runtime would duplicate description text and break the moment a bind
// gains a comment or multi-line expression; the cheatsheet is curated
// documentation, not a config dump. When a bind changes, update both files.
//
// Layout: one card, grouped sections with muted headers. Each bind row
// renders its combo as keycap pills ([SUPER] + [SHIFT] + [C]) followed by
// a plain-language description. A Flickable caps the card height so long
// lists scroll instead of overflowing small screens.
PanelWindow {
    id: root

    property bool isOpen: false

    // --- Static keybinding model (mirror of keybindings.lua) -----------------
    // Each row: keys = array of keycap labels, desc = plain-language action.
    // Modifier order matches how the binds are written (SUPER first).
    readonly property var groups: [
        {
            title: "Applications",
            binds: [
                { keys: ["SUPER", "Q"], desc: "Open terminal (Ghostty)" },
                { keys: ["SUPER", "B"], desc: "Open browser (Firefox)" }
            ]
        },
        {
            title: "Launcher & tools",
            binds: [
                { keys: ["ALT", "Space"], desc: "App launcher" },
                { keys: ["SUPER", "W"], desc: "Wallpaper picker" },
                { keys: ["SUPER", "SHIFT", "C"], desc: "Pick color from screen" },
                { keys: ["SUPER", "H"], desc: "Toggle this cheatsheet" }
            ]
        },
        {
            title: "Window management",
            binds: [
                { keys: ["ALT", "F4"], desc: "Close window" },
                { keys: ["SUPER", "V"], desc: "Toggle floating" },
                { keys: ["SUPER", "F"], desc: "Float at 60% size, centered" },
                { keys: ["F11"], desc: "Toggle fullscreen" },
                { keys: ["SUPER", "P"], desc: "Toggle pseudo-tiling" },
                { keys: ["SUPER", "J"], desc: "Toggle split direction" },
                { keys: ["SUPER", "LMB"], desc: "Move window" },
                { keys: ["SUPER", "RMB"], desc: "Resize window" }
            ]
        },
        {
            title: "Focus",
            binds: [
                { keys: ["SUPER", "←"], desc: "Focus window left" },
                { keys: ["SUPER", "→"], desc: "Focus window right" },
                { keys: ["SUPER", "↑"], desc: "Focus window up" },
                { keys: ["SUPER", "↓"], desc: "Focus window down" }
            ]
        },
        {
            title: "Workspaces",
            binds: [
                { keys: ["SUPER", "1–9", "0"], desc: "Go to workspace 1–10" },
                { keys: ["SUPER", "SHIFT", "1–9", "0"], desc: "Move window to workspace 1–10" },
                { keys: ["SUPER", "S"], desc: "Toggle scratchpad (special workspace)" },
                { keys: ["SUPER", "SHIFT", "S"], desc: "Move window to scratchpad" },
                { keys: ["SUPER", "Scroll"], desc: "Cycle workspaces" }
            ]
        },
        {
            title: "Media",
            binds: [
                { keys: ["Vol +"], desc: "Volume up" },
                { keys: ["Vol −"], desc: "Volume down" },
                { keys: ["Mute"], desc: "Mute speakers" },
                { keys: ["Mic"], desc: "Mute microphone" },
                { keys: ["Bright +"], desc: "Brightness up" },
                { keys: ["Bright −"], desc: "Brightness down" }
            ]
        },
        {
            title: "Screenshots",
            binds: [
                { keys: ["Print"], desc: "Full screen → editor (satty)" },
                { keys: ["SHIFT", "Print"], desc: "Select area → editor (satty)" },
                { keys: ["CTRL", "Print"], desc: "Full screen → clipboard" },
                { keys: ["CTRL", "SHIFT", "Print"], desc: "Select area → clipboard" }
            ]
        },
        {
            title: "Session / power",
            binds: [
                { keys: ["SUPER", "M"], desc: "Exit Hyprland" },
                { keys: ["SUPER", "L"], desc: "Lock screen (hyprlock)" },
                { keys: ["Esc"], desc: "Close popups / this window" }
            ]
        }
    ]

    // The window exists only while open.
    visible: root.isOpen
    color: "transparent"

    // Fullscreen invisible overlay; the card sits on top of it.
    exclusiveZone: -1
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:cheatsheet"

    // No exclusive keyboard focus: it would make Hyprland route all pointer
    // events here (see PopupBase). Esc closing is handled by the global
    // non-consuming bind calling the shell's IPC ("popup" target).

    function open() {
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
    }

    function toggle() {
        root.isOpen ? root.close() : root.open();
    }

    // --- Visuals -------------------------------------------------------------

    // Fullscreen click-outside catcher; the card consumes clicks inside it.
    MouseArea {
        anchors.fill: parent
        onPressed: root.close()
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Theme.cheatsheetWidth
        // listColumn.implicitHeight already includes its own top/bottom
        // padding, so no extra padding is added here.
        height: Math.min(listColumn.implicitHeight, Theme.cheatsheetMaxHeight)
        radius: Theme.pillRadius
        color: Theme.pillBackground
        border.width: 1
        border.color: Theme.highlight

        // Swallows clicks inside the card so the fullscreen catcher below
        // never sees them: the window only closes on a click OUTSIDE the
        // card.
        MouseArea {
            anchors.fill: parent
        }

        // Scrollable list: the card height is capped by the theme, so the
        // content may exceed it. The clip + contentY pattern keeps the
        // column's implicitHeight measurable (the card sizes from it).
        Flickable {
            id: flick

            anchors.fill: parent
            contentWidth: width
            contentHeight: listColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            maximumFlickVelocity: 4000

            Column {
                id: listColumn

                width: flick.width
                spacing: Theme.cheatsheetSectionSpacing

                topPadding: Theme.cheatsheetPadding
                bottomPadding: Theme.cheatsheetPadding
                leftPadding: Theme.cheatsheetPadding
                rightPadding: Theme.cheatsheetPadding

                Repeater {
                    model: root.groups

                    Column {
                        id: groupColumn

                        required property var modelData

                        width: parent.width
                        spacing: Theme.cheatsheetRowSpacing

                        // Muted section header, same look as the popup
                        // section headers in PowerMenuPopup.
                        Text {
                            text: groupColumn.modelData.title
                            font.pixelSize: Theme.fontSize
                            font.family: Theme.fontFamily
                            font.bold: Theme.fontBold
                            color: Theme.textMuted
                        }

                        Repeater {
                            model: groupColumn.modelData.binds

                            BindRow {}
                        }
                    }
                }
            }
        }
    }

    // Wheel accelerator covering the whole window, on top of the card:
    // Flickable's built-in wheel step is tiny (~20px per notch), so a full
    // list scroll takes forever. acceptedButtons: NoButton keeps all
    // clicks passing through (click-outside close and drag/flick still
    // work); only wheel events are consumed here. Fractional deltas
    // (smooth wheels/trackpads) accumulate until a full notch is reached.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        property real accumulated: 0
        onWheel: wheel => {
            accumulated += wheel.angleDelta.y;
            while (Math.abs(accumulated) >= 120) {
                const step = accumulated > 0 ? -110 : 110;
                accumulated -= accumulated > 0 ? 120 : -120;
                const target = flick.contentY + step;
                flick.contentY = Math.max(0, Math.min(target, flick.contentHeight - flick.height));
            }
        }
    }

    // One bind: keycap pills + plain-language description. The description
    // sits in a FIXED left column (Theme.cheatsheetDescColumn) so all
    // descriptions align vertically regardless of combo length — far easier
    // to scan than flowing descriptions after variable-width combos.
    component BindRow: Item {
        id: row

        required property var modelData

        readonly property var caps: modelData.keys

        width: parent.width
        height: Math.max(comboRow.implicitHeight, rowDesc.implicitHeight)

        Row {
            id: comboRow

            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: row.caps

                Cap {}
            }
        }

        Text {
            id: rowDesc

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Theme.cheatsheetDescColumn
            anchors.right: parent.right
            text: row.modelData.desc
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            color: Theme.text
            elide: Text.ElideRight
        }
    }

    // One keycap pill; caps after the first get a leading "+" separator.
    // Fully self-contained (only Repeater-provided modelData/index), so no
    // id lookups cross component boundaries.
    component Cap: Row {
        id: cap

        required property string modelData
        required property int index

        spacing: 4

        Text {
            visible: cap.index > 0
            anchors.verticalCenter: parent.verticalCenter
            text: "+"
            font.pixelSize: Theme.fontSize - 2
            font.family: Theme.fontFamily
            color: Theme.textMuted
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: capText.implicitWidth + 12
            height: capText.implicitHeight + 6
            radius: Theme.pillRadius
            // Solid surface tint instead of a low-opacity highlight: the
            // keycaps must read clearly against the dark card.
            color: Theme.surface1
            border.width: 1
            border.color: Theme.surface2

            Text {
                id: capText

                anchors.centerIn: parent
                text: cap.modelData
                font.pixelSize: Theme.fontSize - 2
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                color: Theme.text
            }
        }
    }
}
