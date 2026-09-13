import Quickshell.Services.Pipewire
import QtQuick
import "../../theme"
import "../../utils"
import "../../widgets"

// Audio pill — output (sink) + microphone (source) inside a single Pill.
// Uses Quickshell.Services.Pipewire exclusively: Pipewire.defaultAudioSink/
// defaultAudioSource, audio.volume (0..1) and audio.muted. No wpctl fallback.
// PwObjectTracker keeps both PwNodes bound so audio/properties stay reactive.
// Pill remains visible when sink/source transiently null; shows N/A instead of collapsing.
Pill {
    id: root

    // Fixed width: pill never resizes with text changes (1%→100%, N/A, icon swap on mute).
    // Muted keeps number (󰖁 42% /  42%) — only icon changes, so no " Muted" width inflation.
    // Probes below compute exact maxima; pill width = probes + spacing + padding.
    readonly property int sinkFixedWidth: Math.max(sinkProbe100.implicitWidth, sinkProbeMuted100.implicitWidth, sinkProbeNa.implicitWidth)
    readonly property int sourceFixedWidth: Math.max(sourceProbe100.implicitWidth, sourceProbeMuted100.implicitWidth, sourceProbeNa.implicitWidth)
    width: sinkFixedWidth + sourceFixedWidth + Theme.itemSpacing + Theme.pillPaddingH

    // Pipewire nodes — may be null briefly during swaps.
    property var sink: Pipewire.defaultAudioSink
    property var sinkAudio: sink ? sink.audio : null
    property var source: Pipewire.defaultAudioSource
    property var sourceAudio: source ? source.audio : null

    readonly property int sinkVolume: sinkAudio ? Math.round(sinkAudio.volume * 100) : 0
    readonly property int sourceVolume: sourceAudio ? Math.round(sourceAudio.volume * 100) : 0

    // Headphone detection — only evaluated when node is bound (PwObjectTracker).
    // When muted, show muted variant (󰖁 / ) instead of " Muted" text, keeping volume number.
    function sinkIcon(): string {
        if (!sink || !sinkAudio)
            return "󰖁";
        if (sinkAudio.muted)
            return "󰖁"; // muted — bar variant, keep number in text
        const props = sink.properties || {};
        const deviceType = [props["device.form_factor"], props["device.icon_name"], props["api.bluez5.icon"], sink.name, sink.description].filter(Boolean).join(" ").toLowerCase();
        if (deviceType.includes("headphone") || deviceType.includes("headset") || deviceType.includes("bluez_output"))
            return "";
        if (root.sinkVolume === 0)
            return "";
        if (root.sinkVolume < 50)
            return "";
        return "";
    }

    function micIcon(): string {
        if (!source || !sourceAudio)
            return "";
        return sourceAudio.muted ? "" : "";
    }

    function clampVolume(v: int): int {
        return Math.max(0, Math.min(100, Math.round(v)));
    }

    function setSinkVolume(pct: int): void {
        if (!sinkAudio)
            return;
        sinkAudio.volume = clampVolume(pct) / 100;
    }

    function setSourceVolume(pct: int): void {
        if (!sourceAudio)
            return;
        sourceAudio.volume = clampVolume(pct) / 100;
    }

    function stepSink(direction: int): void {
        // 1% per wheel notch, clamp 0..100
        root.setSinkVolume(root.sinkVolume + direction * 1);
    }

    function stepSource(direction: int): void {
        root.setSourceVolume(root.sourceVolume + direction * 1);
    }

    // Keep PwNodes bound so audio/properties are not stale.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    ScrollHandler {
        id: sinkScroll
        threshold: 120
        onStepped: direction => root.stepSink(direction)
    }

    ScrollHandler {
        id: sourceScroll
        threshold: 120
        onStepped: direction => root.stepSource(direction)
    }

    // Hidden probes for fixed-width calculation (never visible, same font).
    Text {
        id: sinkProbe100
        visible: false
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        text: " 100%"
    }
    Text {
        id: sinkProbeMuted100
        visible: false
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        text: "󰖁 100%"
    }
    Text {
        id: sinkProbeNa
        visible: false
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        text: "󰖁 N/A"
    }
    Text {
        id: sourceProbe100
        visible: false
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        text: " 100%"
    }
    Text {
        id: sourceProbeMuted100
        visible: false
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        text: " 100%"
    }
    Text {
        id: sourceProbeNa
        visible: false
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        text: " N/A"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.itemSpacing

        // Sink side — fixed width from probes; self-contained click + wheel (only affects output)
        Item {
            id: sinkItem
            width: root.sinkFixedWidth
            height: sinkText.implicitHeight

            Text {
                id: sinkText
                anchors.centerIn: parent
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                color: "#89b4fa"
                text: {
                    if (!root.sinkAudio)
                        return `${root.sinkIcon()} N/A`;
                    return `${root.sinkIcon()} ${root.sinkVolume}%`;
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    if (root.sinkAudio)
                        root.sinkAudio.muted = !root.sinkAudio.muted;
                }
                onWheel: wheel => {
                    sinkScroll.handleWheel(wheel.angleDelta.y);
                    wheel.accepted = true;
                }
            }
        }

        // Source side — fixed width from probes; self-contained click + wheel (only affects mic)
        Item {
            id: sourceItem
            width: root.sourceFixedWidth
            height: sourceText.implicitHeight

            Text {
                id: sourceText
                anchors.centerIn: parent
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                color: "#cba6f7"
                text: {
                    if (!root.sourceAudio)
                        return `${root.micIcon()} N/A`;
                    return `${root.micIcon()} ${root.sourceVolume}%`;
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    if (root.sourceAudio)
                        root.sourceAudio.muted = !root.sourceAudio.muted;
                }
                onWheel: wheel => {
                    sourceScroll.handleWheel(wheel.angleDelta.y);
                    wheel.accepted = true;
                }
            }
        }
    }
}
