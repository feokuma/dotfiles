import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../../theme"

// Audio popup: output (sink) + microphone (source) sliders, opened by
// clicking any side of the Audio pill. Replaces click-to-mute on the pill;
// mute now lives on the row icon buttons inside this popup.
//
// Sits below the bar's right side, over the Audio pill area. Volume state
// and writes come from the Audio pill instance (audioRef) so Pipewire
// logic (incl. the BlueZ wpctl path) is not duplicated.
//
// Single-window overlay like Launcher: per-monitor hosts deferred until a
// multi-monitor strategy exists.
PanelWindow {
    id: root

    property bool isOpen: false
    // Audio pill instance, wired from shell.qml — owns Pipewire state and
    // the write paths (native + BlueZ/wpctl), so they are not duplicated.
    property var audioRef: null

    function open() {
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
    }

    function toggle() {
        root.isOpen ? root.close() : root.open();
    }

    visible: root.isOpen
    color: "transparent"
    // Backdrop model: a fullscreen invisible window catches every click
    // (closes the popup), while the card consumes clicks inside it. This
    // replaces a HyprlandFocusGrab, which closed the popup mid-drag because
    // the compositor re-evaluates focus while the pointer moves.
    exclusiveZone: -1
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    margins.top: Theme.barHeight + 6

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:audio-popup"

    // Fullscreen click-outside catcher; the card sits on top of it.
    MouseArea {
        anchors.fill: parent
        onPressed: root.close()
    }

    // Rounded card, opaque like the launcher (pill opacity would wash
    // the border out).
    readonly property int popupPadding: 14
    readonly property int popupWidth: 350

    Rectangle {
        id: panel

        anchors {
            top: parent.top
            right: parent.right
            rightMargin: Theme.barMargin
        }
        width: root.popupWidth
        height: content.implicitHeight + content.anchors.margins * 2
        radius: Theme.pillRadius
        color: Theme.pillBackground
        border.width: 1
        border.color: Theme.highlight
        clip: true

        opacity: root.isOpen ? 1 : 0

        // Entrance like the Launcher, but dropping from the bar downward:
        // fade plus a short slide-down (Launcher slides up from below).
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
            topPadding: root.popupPadding
            bottomPadding: root.popupPadding
            leftPadding: root.popupPadding
            rightPadding: root.popupPadding
            spacing: 10

            Text {
                // Cosmetic header row anchors the popup semantics.
                text: "Volume"
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                color: Theme.textMuted
            }

            // Output (sink) row: icon doubles as the mute toggle.
            VolumeSlider {
                width: content.width - content.leftPadding - content.rightPadding
                // Output glyph (󰕾 family) renders visually smaller than the
                // mic glyph (󰋎); nudge it up to match optically.
                iconAdjust: 3
                iconUnmuted: {
                    const vol = root.audioRef ? root.audioRef.sinkVolume : 0;
                    if (vol === 0)
                        return "󰕿";
                    return vol < 50 ? "󰖀" : "󰕾";
                }
                iconMuted: "󰖁"
                muted: root.audioRef ? root.audioRef.sinkMuted : true
                value: root.audioRef ? root.audioRef.sinkVolume : 0
                accent: Theme.accent
                onToggleMuted: {
                    if (root.audioRef)
                        root.audioRef.toggleSinkMute();
                }
                onMoved: v => {
                    if (root.audioRef)
                        root.audioRef.setSinkVolume(Math.round(v));
                }
            }

            // Output device selector — click the header to expand the list.
            DeviceDropdown {
                width: content.width - content.leftPadding - content.rightPadding
                label: "Output device"
                nodes: root.audioRef ? root.audioRef.sinkNodes : []
                currentId: root.audioRef ? root.audioRef.defaultSinkId : -1
                accent: Theme.accent
                onSelect: node => {
                    if (root.audioRef)
                        root.audioRef.setDefaultSink(node);
                }
            }

            // Microphone (source) row. Same glyphs as the bar pill
            // (FontAwesome U+F130 mic / U+F131 mic-mute) for visual
            // consistency; the MDI glyph used before (󰋎) is a headset.
            VolumeSlider {
                width: content.width - content.leftPadding - content.rightPadding
                iconUnmuted: "\uF130"
                iconMuted: "\uF131"
                muted: root.audioRef ? root.audioRef.sourceMuted : true
                value: root.audioRef ? root.audioRef.sourceVolume : 0
                accent: Theme.accentSecondary
                onToggleMuted: {
                    if (root.audioRef)
                        root.audioRef.toggleSourceMute();
                }
                onMoved: v => {
                    if (root.audioRef)
                        root.audioRef.setSourceVolume(Math.round(v));
                }
            }

            // Input device selector — same collapsible list, one for sources.
            DeviceDropdown {
                width: content.width - content.leftPadding - content.rightPadding
                label: "Input device"
                nodes: root.audioRef ? root.audioRef.sourceNodes : []
                currentId: root.audioRef ? root.audioRef.defaultSourceId : -1
                accent: Theme.accentSecondary
                onSelect: node => {
                    if (root.audioRef)
                        root.audioRef.setDefaultSource(node);
                }
            }
        }
    }

    // Inline component: one slider row (mute icon + track + percent).
    component VolumeSlider: Item {
        id: row

        property string iconUnmuted
        property string iconMuted
        property bool muted
        property real value
        property color accent
        // Glyph-specific visual size compensation; the Material Design
        // icons do not share the same em-box fill, so per-row nudging
        // keeps output/mic icons optically equal.
        property int iconAdjust: 0
        signal toggleMuted
        signal moved(real newValue)

        // While dragging, keep the visual in sync even if the reactive
        // volume briefly lags behind the pointer (Slider owns its value
        // while pressed; the Binding hands control back when released).
        property real dragValue: -1
        readonly property real shownValue: row.dragValue >= 0 ? row.dragValue : row.value

        height: 34

        Text {
            id: muteIcon

            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 4 + row.iconAdjust
            color: row.muted ? Theme.textMuted : row.accent
            text: row.muted ? row.iconMuted : row.iconUnmuted

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: row.toggleMuted()
            }
        }

        // Native Slider (QtQuick.Controls) restyled with the popup visuals:
        // background = track + fill, handle = draggable knob. Replaces the
        // hand-rolled MouseArea/knob math; Slider owns pressed state, drag
        // handling and availableWidth centering. External value updates
        // (reactive volume) reach the slider only while it is not pressed.
        Slider {
            id: trackWrap

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: muteIcon.right
            anchors.leftMargin: 12
            anchors.right: percent.left
            anchors.rightMargin: 8
            height: Theme.popupTrackHeight

            from: 0
            to: 100
            snapMode: Slider.NoSnap

            onMoved: row.moved(value)
            onPressedChanged: {
                if (!pressed) {
                    row.dragValue = -1;
                    row.moved(value);
                }
            }

            Binding {
                target: trackWrap
                property: "value"
                value: row.shownValue
                when: !trackWrap.pressed
                restoreMode: Binding.RestoreNone
            }
            // While pressed the reactive volume may lag a notch; keep the
            // label honest with the slider's own value.
            Binding {
                target: row
                property: "dragValue"
                value: trackWrap.value
                when: trackWrap.pressed
                restoreMode: Binding.RestoreNone
            }

            background: Item {
                implicitWidth: trackWrap.width
                implicitHeight: trackWrap.height

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.crust
                    border.width: 1
                    border.color: row.accent
                    opacity: 0.85
                }

                // Filled portion of the track, up to the knob center.
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height - 2
                    x: 1
                    width: Math.max(
                        2,
                        1 + (trackWrap.availableWidth * trackWrap.visualPosition) + trackWrap.height / 2
                    )
                    radius: height / 2
                    color: row.accent
                    visible: !row.muted
                    opacity: 0.9
                }
            }

            // Knob runs slightly larger than the track so it reads as a
            // draggable handle rather than a track endpoint. The Slider does
            // not position an overridden handle item; do it here the same way
            // the Basic style template does.
            handle: Rectangle {
                x: trackWrap.visualPosition * (trackWrap.availableWidth - width)
                y: (trackWrap.height - height) / 2
                width: trackWrap.height + 6
                height: width
                radius: width / 2
                color: row.muted ? Theme.textMuted : row.accent
            }
        }

        Text {
            id: percent

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            width: 42
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: Theme.text
            text: row.muted ? "—" : `${Math.round(row.shownValue)}%`
        }

        onValueChanged: {
            if (Math.abs(row.dragValue - row.value) < 2)
                row.dragValue = -1;
        }
    }

    // Collapsible device list: header row shows the active device name and a
    // chevron; the body expands with its own height animation (the card's
    // height follows content.implicitHeight, so the popup grows with it).
    component DeviceDropdown: Column {
        id: dd

        property string label
        property var nodes: []
        property int currentId
        property color accent
        property bool expanded: false
        signal select(var node)

        spacing: 2

        // Header: click anywhere to expand/collapse. Shows the currently
        // active device name so state stays visible while collapsed.
        readonly property var currentNode: {
            for (let i = 0; i < dd.nodes.length; i++) {
                if (dd.nodes[i].id === dd.currentId)
                    return dd.nodes[i];
            }
            return null;
        }
        readonly property string currentNodeName: currentNode ? (currentNode.description || currentNode.nickname || currentNode.name) : "N/A"

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
                // Section label + active device, muted so the device name reads
                // as the payload rather than a second title.
                text: `${dd.label} — ${dd.currentNodeName}`
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
                    // Friendly empty state: transient Pipewire churn can
                    // momentarily produce zero entries.
                    visible: dd.nodes.length === 0
                    text: "No devices found"
                    font.pixelSize: Theme.fontSize - 1
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                Repeater {
                    model: dd.nodes

                    delegate: DeviceRow {
                        // Declaring modelData `required` makes the model role a
                        // real property of the delegate — inline components
                        // don't reliably receive the context-injected value.
                        required property var modelData
                        node: modelData
                        accent: dd.accent
                        active: modelData.id === dd.currentId
                        onSelect: node => dd.select(node)
                    }
                }
            }
        }
    }

    // One device row: name (elided) + a check mark for the active device.
    component DeviceRow: Item {
        id: row

        required property var node
        property color accent
        property bool active
        signal select(var node)

        readonly property string deviceName: node ? (node.description || node.nickname || node.name) : ""

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
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: check.left
            anchors.rightMargin: 8
            text: row.deviceName
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
            onClicked: row.select(row.node)
        }
    }
}
