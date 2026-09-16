import Quickshell
import Quickshell.Wayland
import QtQuick
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

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
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
        // sinkVolume briefly lags behind the pointer.
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

        // Track + handle drawn at full width; usable region sits between the
        // icon and the percent label.
        Item {
            id: trackWrap

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: muteIcon.right
            anchors.leftMargin: 12
            anchors.right: percent.left
            anchors.rightMargin: 8
            height: Theme.popupTrackHeight

            // Usable knob travel: knob center goes 0 → width - knob.
            // Knob runs slightly larger than the track so it reads as a
            // draggable handle rather than a track endpoint.
            readonly property real knobSize: height + 6
            readonly property real usable: width - knobSize

            Rectangle {
                id: track

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
                width: Math.max(2, 1 + (trackWrap.usable * row.shownValue / 100) + trackWrap.height / 2)
                radius: height / 2
                color: row.accent
                visible: !row.muted
                opacity: 0.9
            }

            // Handle knob, vertically centered on the track.
            Rectangle {
                id: knob

                x: trackWrap.usable * row.shownValue / 100
                y: (trackWrap.height - width) / 2
                width: trackWrap.knobSize
                height: trackWrap.knobSize
                radius: width / 2
                color: row.muted ? Theme.textMuted : row.accent
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => trackWrap.setValueFrom(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        trackWrap.setValueFrom(mouse.x);
                }
                // Drop the drag override once the pointer lets go; the
                // reactive binding takes over again.
                onReleased: row.dragValue = -1
                onCanceled: row.dragValue = -1
            }

            function setValueFrom(mouseX: real): void {
                const v = Math.max(0, Math.min(100, ((mouseX - trackWrap.knobSize / 2) / trackWrap.usable) * 100));
                row.dragValue = v;
                row.moved(v);
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
}
