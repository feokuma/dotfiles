import Quickshell
import Quickshell.Io
import QtQuick
import "../../theme"
import "../../utils"
import "../../widgets"

// Brightness pill. Container visuals live in Pill; content here.
// Uses FileView for sysfs reading (initial load) and udevadm monitor
// for reactive updates — no polling, no watchChanges on sysfs (stale).
// Writes via brightnessctl only (brightnessctl --quiet set <pct>%).
// Visible only when a valid backlight is available (max > 0).
Pill {
    id: root

    // Hide when no backlight device is available.
    visible: root.maxBrightness > 0 && root.brightnessReady

    width: brightnessText.width + Theme.pillPaddingH

    // Paths — fixed to intel_backlight for current machine (eDP-1).
    // Multi-backlight support can add a `device` property later.
    readonly property string brightnessPath: "/sys/class/backlight/intel_backlight/brightness"
    readonly property string maxBrightnessPath: "/sys/class/backlight/intel_backlight/max_brightness"

    // Raw values from sysfs (parsed from FileView.text()).
    property int rawBrightness: 0
    property int maxBrightness: 0
    property bool brightnessReady: false
    property bool maxReady: false

    // Scroll smoothing — shared via utils/ScrollHandler (threshold 120).

    // Derived percentage 0-100 from sysfs.
    readonly property int level: root.maxBrightness > 0 ? Math.round((root.rawBrightness / root.maxBrightness) * 100) : 0

    // MDI brightness-1..7: 󰃜 F00DC, 󰃝 F00DD, 󰃞 F00DE, 󰃟 F00DF, 󰃠 F00E0, 󰃡 F00E1, 󰃢 F00E2
    // Corrigido: ordem monotônica crescente + thresholds lineares (20% steps).
    // Antes 0% → 󰃞 (F00DE) e 15% → 󰃝 (F00DD) estavam invertidos (0% mais claro que 15%);
    // e 55%+ usava 󰃠/󰃡/󰃢 muito próximos sem distinção clara.
    function brightnessIcon(): string {
        const lvl = root.level;
        if (lvl <= 0)
            return "󰃜"; // F00DC off/dimmest
        if (lvl <= 20)
            return "󰃞"; // F00DD
        if (lvl <= 40)
            return "󰃟"; // F00DE
        if (lvl <= 60)
            return "󰃟"; // F00DF  ~55% agora cai aqui (médio) em vez de 󰃠
        if (lvl <= 80)
            return "󰃠"; // F00E0
        if (lvl <= 95)
            return "󰃡"; // F00E1
        return "󰃢"; // F00E2 brightest
    }

    function setLevel(newLevel: int): void {
        const clamped = Math.max(0, Math.min(100, Math.round(newLevel)));
        // brightnessctl handles permission via logind/video group; no sudo.
        Quickshell.execDetached(["brightnessctl", "--quiet", "set", `${clamped}%`]);
        // Do not optimistically set rawBrightness — FileView will update via sysfs watch.
    }

    function step(direction: int): void {
        // direction is -1 or 1; each step is 1% (ajuste fino).
        root.setLevel(root.level + direction * 1);
    }

    function cyclePreset(): void {
        const cur = root.level;
        let next;
        if (cur < 40)
            next = 50;
        else if (cur < 80)
            next = 100;
        else
            next = 15;
        root.setLevel(next);
    }

    ScrollHandler {
        id: scrollHandler
        threshold: 120
        onStepped: direction => root.step(direction)
    }

    function parseIntSafe(text: string): int {
        const v = parseInt(text.trim(), 10);
        return isNaN(v) ? 0 : v;
    }

    // --- sysfs watchers ---
    // Tested: FileView.watchChanges on sysfs returns stale text after
    // brightnessctl changes. Keep FileView for reading, rely on udevadm
    // to trigger reload() for immediate updates (validated: 60%->240 etc).
    FileView {
        id: brightnessFile
        path: root.brightnessPath
        watchChanges: false
        blockLoading: true
        onLoaded: {
            root.brightnessReady = true;
            root.rawBrightness = root.parseIntSafe(brightnessFile.text());
        }
        onLoadFailed: root.brightnessReady = false
    }

    FileView {
        id: maxFile
        path: root.maxBrightnessPath
        watchChanges: false
        blockLoading: true
        onLoaded: {
            root.maxReady = true;
            root.maxBrightness = root.parseIntSafe(maxFile.text());
        }
        onLoadFailed: {
            root.maxReady = false;
            root.maxBrightness = 0;
        }
    }

    // udev monitor — reactive, no polling.
    Process {
        id: udevMonitor
        command: ["udevadm", "monitor", "--property", "--subsystem-match=backlight"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.trim() === "ACTION=change")
                    brightnessFile.reload();
            }
        }
    }

    Text {
        id: brightnessText
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        color: Theme.text
        text: `${root.brightnessIcon()} ${root.level}%`
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: root.cyclePreset()
        onWheel: wheel => {
            scrollHandler.handleWheel(wheel.angleDelta.y);
            wheel.accepted = true;
        }
    }
}
