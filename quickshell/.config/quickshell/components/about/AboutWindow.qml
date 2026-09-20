import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import QtQuick
import "../../theme"

// Floating "About this system" window, centered on the screen.
//
// Opened by the PowerMenuPopup "About this system" row: shell.qml attaches
// this component as `PowerMenuPopup.aboutWindow`, whose row calls open().
// The about window is not a bar popup and stays outside PopupManager on
// purpose: it may coexist with a bar popup being open.
//
// Structure mirrors the bar popups: a fullscreen transparent PanelWindow
// (exclusiveZone -1, so the desktop itself is untouched while open) whose
// click-outside catcher closes it, with the card anchored to the exact
// center — resolution/scale independent, no screen dimensions involved.
//
// Data policy: fastfetch is only the field reference, not the source.
// Static identity comes from files/env via FileView (loaded on demand),
// battery comes from the native UPower integration, and values that change
// (uptime, memory, packages, disk, IP, monitors' refresh rates...) are
// refreshed by one-shot processes every time the window opens — no polling.
// Hyprland refresh rates come from a focused hyprctl fallback because
// QuickshellScreenInfo has no refreshRate property on this build (0.3.1).
PanelWindow {
    id: root

    property bool isOpen: false

    // --- Static system identity (files + environment) -----------------------
    // PRETTY_NAME="..." from /etc/os-release, if parse succeeds; arch from
    // uname -m (one-shot below), unless pretty name already carries it.
    readonly property string osName: {
        const m = /PRETTY_NAME="?([^"\n]+)"?/.exec(osRelease.text());
        const base = m ? m[1] : "Unknown";
        return base.includes(arc) ? base : base + " " + arc;
    }
    property string arc: ""
    // /proc/version: "Linux version <release> (...)".
    readonly property string kernelVersion: {
        const m = /Linux version (\S+)/.exec(procVersion.text());
        return m ? m[1] : "";
    }
    // /proc/sys/kernel/hostname.
    readonly property string hostName: procHostname.text().trim()
    // "model name : Intel..." from /proc/cpuinfo (first core entry wins).
    readonly property string cpuModel: {
        const m = /model name\s*:\s*(.+)/.exec(procCpuInfo.text());
        return m ? m[1].trim() : "";
    }
    // Vendor/model (+ version) from the DMI id files. product_name already
    // carries the brand line fastfetch shows, so use it as-is (+ version).
    readonly property string hostMachine: {
        const version = dmiVersion.text().trim();
        const name = dmiName.text().trim();
        if (name.length === 0)
            return sysVendor.text().trim();
        return version.length > 0 ? name + " (" + version + ")" : name;
    }

    // Shell/desktop appearance: process environment (set by the Hyprland
    // session environment.lua) gives fastfetch parity without fastfetch.
    readonly property string shellName: (Quickshell.env("SHELL") ?? "").split("/").pop()
    readonly property string wmName: (Quickshell.env("XDG_CURRENT_DESKTOP") ?? "") + " (Wayland)"
    readonly property string gtkTheme: Quickshell.env("GTK_THEME") ?? "Adwaita"
    readonly property string cursorInfo: (Quickshell.env("XCURSOR_THEME") ?? "default") + " (" + (Quickshell.env("XCURSOR_SIZE") ?? "?") + "px)"
    readonly property string userName: Quickshell.env("USER") ?? ""
    readonly property string localeName: Quickshell.env("LANG") ?? ""
    readonly property string fontName: Theme.fontFamily

    // --- One-shot refreshed values (re-read every open) ----------------------
    property string uptimeInfo: ""
    property int packageCount: 0
    // Raw kB values from /proc/meminfo; memoryInfo concatenates them.
    property int memTotalKb: 0
    property int memAvailableKb: 0
    property int swapTotalKb: 0
    property string diskInfo: ""
    property string localIp: ""
    property string gpuInfo: ""
    // Monitor name -> refresh rate in Hz (hyprctl one-shot below).
    property var monitorRates: ({})

    readonly property string memoryInfo: {
        if (memTotalKb <= 0)
            return "...";
        const used = memTotalKb - memAvailableKb;
        const pct = Math.round(100 * used / memTotalKb);
        return fmtKib(used) + " / " + fmtKib(memTotalKb) + " (" + pct + "%)";
    }
    readonly property string swapInfo: swapTotalKb > 0 ? fmtKib(swapTotalKb) : "Disabled"

    readonly property var batteryDevice: {
        // UPower.devices carries leftover/phantom entries; require the
        // battery type AND a sane percentage. (0.3.1 has no
        // UPower.isLaptopBatteryPresent; find the laptop battery directly.)
        const candidates = Array.from(UPower.devices.values).filter(d => d.type === UPowerDeviceType.Battery && d.percentage > 0 && d.percentage <= 100);
        return candidates.length > 0 ? candidates[0] : null;
    }
    function batterySuffix(state: int): string {
        const labels = {};
        labels[UPowerDeviceState.Charging] = "[Charging]";
        labels[UPowerDeviceState.Discharging] = "[Discharging]";
        labels[UPowerDeviceState.FullyCharged] = "[Full]";
        const label = labels[state];
        return label ? " " + label : "";
    }
    readonly property string batteryInfo: {
        if (!batteryDevice)
            return "Not detected";
        const dev = batteryDevice;
        return (dev.percentage * 100) + "%" + batterySuffix(dev.state);
    }

    // One row per connected screen. QuickshellScreenInfo has no refreshRate
    // and no fractional-safe scale on 0.3.1, so resolution, refresh rate
    // and Hyprland scale all come from the hyprctl one-shot below; the
    // Quickshell screen object only provides the fallback fields.
    readonly property var displayRows: Array.from(Quickshell.screens).map(screen => {
        const rates = monitorRates[screen.name];
        return {
            label: "Display (" + screen.name + ")",
            value: rates ? rates.res + " @ " + Math.round(rates.hz) + " Hz" + " (scale " + rates.scale + ")" : Math.round(screen.width * screen.devicePixelRatio) + "x" + Math.round(screen.height * screen.devicePixelRatio) + " @ " + screen.devicePixelRatio + "x"
        };
    })

    // Arch logo, fastfetch-style sidebar (standard Arch ASCII art). Rendered
    // as one multi-line Text; mono font keeps the art aligned.
    readonly property var archLogoLines: ["                   -`", "                  .o+`", "                 `ooo/", "                `+oooo:", "               `+oooooo:", "               -+oooooo+:", "             `/:-:++oooo+:", "            `/++++/+++++++:", "           `/++++++++++++++:", "          `/+++ooooooooooooo/`", "         ./ooosssso++osssssso+`", "        .oossssso-````/ossssss+`", "       -osssssso.      :ssssssso.", "      :osssssss/        osssso+++.", "     /ossssssss/        +ssssooo/-", "   `/ossssso+/:-        -:/+osssso+-", "  `+sso+:-`                 `.-/+oso:", " `++:.                           `-/+/", " `                                 `  "]
    readonly property string archLogo: archLogoLines.map(line => line.replace(/[ \t]+$/, "")).join("\n")

    // The rendered info list in fastfetch order; per-monitor Display rows are
    // spliced in where fastfetch prints them.
    readonly property var infoRows: [
        {
            label: "OS",
            value: osName
        },
        {
            label: "Host",
            value: hostMachine
        },
        {
            label: "Kernel",
            value: kernelVersion
        },
        {
            label: "Uptime",
            value: uptimeInfo
        },
        {
            label: "Packages",
            value: packageCount > 0 ? packageCount + " (pacman)" : "..."
        },
        {
            label: "Shell",
            value: shellName
        },
        {
            label: "GPU",
            value: gpuInfo
        },
        ...displayRows,
        {
            label: "Window Manager",
            value: wmName
        },
        {
            label: "Theme",
            value: gtkTheme
        },
        {
            label: "Cursor",
            value: cursorInfo
        },
        {
            label: "Font",
            value: fontName
        },
        {
            label: "CPU",
            value: cpuModel
        },
        {
            label: "Memory",
            value: memoryInfo
        },
        {
            label: "Swap",
            value: swapInfo
        },
        {
            label: "Disk (/)",
            value: diskInfo
        },
        {
            label: "Local IP",
            value: localIp
        },
        {
            label: "Battery",
            value: batteryInfo
        },
        {
            label: "Locale",
            value: localeName
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
    WlrLayershell.namespace: "quickshell:about"

    function open() {
        root.isOpen = true;
        refreshOneShots();
    }

    function close() {
        root.isOpen = false;
    }

    function toggle() {
        root.isOpen ? root.close() : root.open();
    }

    // Re-read the values that can change between opens.
    function refreshOneShots() {
        uptimeProc.running = true;
        meminfoProc.running = true;
        packagesProc.running = true;
        diskProc.running = true;
        ipProc.running = true;
        gpuProc.running = true;
        monitorRateProc.running = true;
    }

    // kB (per /proc/meminfo) to a human-sized string.
    function fmtKib(kb: int): string {
        if (kb >= 1048576)
            return (kb / 1048576).toFixed(2) + " GiB";
        if (kb >= 1024)
            return (kb / 1024).toFixed(2) + " MiB";
        return kb + " kB";
    }

    // --- Static sources ------------------------------------------------------
    FileView {
        id: osRelease

        path: "/etc/os-release"
    }

    FileView {
        id: procVersion

        path: "/proc/version"
    }

    FileView {
        id: procHostname

        path: "/proc/sys/kernel/hostname"
    }

    FileView {
        id: procCpuInfo

        path: "/proc/cpuinfo"
    }

    FileView {
        id: dmiName

        path: "/sys/class/dmi/id/product_name"
    }

    FileView {
        id: dmiVersion

        path: "/sys/class/dmi/id/product_version"
    }

    FileView {
        id: sysVendor

        path: "/sys/class/dmi/id/sys_vendor"
    }

    // Machine architecture for the OS row (fastfetch parity).
    Process {
        id: arcProc

        command: ["uname", "-m"]
        running: true
        stdout: SplitParser {
            onRead: data => root.arc = data.trim()
        }
    }

    // --- One-shot processes (SplitParser is the reliable stdout path on
    // 0.3.1 — see PowerProfileService.qml) -----------------------------------
    // "<seconds> ..." -> "H hour(s), M minute(s)" like fastfetch.
    Process {
        id: uptimeProc

        command: ["cat", "/proc/uptime"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                const secs = Math.floor(parseFloat(data));
                if (isNaN(secs))
                    return;
                const h = Math.floor(secs / 3600), m = Math.floor((secs % 3600) / 60);
                const parts = [];
                if (h > 0)
                    parts.push(h + (h === 1 ? " hour" : " hours"));
                parts.push(m + (m === 1 ? " min" : " mins"));
                root.uptimeInfo = parts.join(", ");
            }
        }
    }

    // /proc/meminfo: consume the three lines of interest.
    Process {
        id: meminfoProc

        command: ["cat", "/proc/meminfo"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                let m = /^MemTotal:\s+(\d+)/.exec(data);
                if (m)
                    root.memTotalKb = parseInt(m[1]);
                m = /^MemAvailable:\s+(\d+)/.exec(data);
                if (m)
                    root.memAvailableKb = parseInt(m[1]);
                m = /^SwapTotal:\s+(\d+)/.exec(data);
                if (m)
                    root.swapTotalKb = parseInt(m[1]);
            }
        }
    }

    // Installed packages: one line per package; count them.
    Process {
        id: packagesProc

        command: ["pacman", "-Q"]
        running: false
        property int lines: 0
        onRunningChanged: lines = 0
        stdout: SplitParser {
            onRead: packagesProc.lines++
        }
        onExited: root.packageCount = lines
    }

    // Disk: column layout differs with -T, so parse by split and locate
    // the "Use%" column contents in the second line.
    Process {
        id: diskProc

        command: ["df", "-h", "-T", "/"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("Filesystem"))
                    return;
                const f = data.trim().split(/\s+/);
                if (f.length < 7)
                    return;
                // Filesystem Type Size Used Avail Use% Mounted
                root.diskInfo = f[3] + " / " + f[2] + " (" + f[5] + ") - " + f[1];
            }
        }
    }

    // First non-loopback IPv4 address.
    Process {
        id: ipProc

        command: ["ip", "-4", "addr", "show"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                if (root.localIp.length > 0)
                    return;
                const m = /^\s*inet (\d+\.\d+\.\d+\.\d+)\/(\d+)/.exec(data);
                if (!m || m[1] === "127.0.0.1")
                    return;
                // Interface is the last whitespace token of the inet line.
                const tokens = data.trim().split(/\s+/);
                root.localIp = m[1] + "/" + m[2] + " (" + tokens[tokens.length - 1] + ")";
            }
        }
    }

    // lspci -m: 00:02.0 "VGA compatible controller" "Intel Corp." "Device".
    Process {
        id: gpuProc

        command: ["lspci", "-m"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                if (root.gpuInfo.length > 0)
                    return;
                // lspci -m: fields[0]=class, [1]=vendor, [2]=device.
                const fields = data.match(/"([^"]*)"/g);
                if (!fields || fields.length < 3)
                    return;
                const cls = fields[0];
                if (!cls.includes("VGA") && !cls.includes("Display") && !cls.includes("3D"))
                    return;
                root.gpuInfo = fields[2].replace(/"/g, "");
            }
        }
    }

    // Per-monitor geometry/scale: hyprctl's output is sectioned, so the
    // whole document is accumulated and parsed once on exit — much easier
    // to reason about than line-by-line state.
    Process {
        id: monitorRateProc

        command: ["hyprctl", "monitors"]
        running: false
        property string output: ""
        onRunningChanged: output = ""
        stdout: SplitParser {
            onRead: data => monitorRateProc.output += data + "\n"
        }
        onExited: {
            const re = /Monitor (\S+) \(ID\s*\d+\)[\s\S]*?(\d+x\d+)@([\d.]+)[\s\S]*?scale:\s*([\d.]+)/g;
            root.monitorRates = {};
            let m;
            while ((m = re.exec(output)) !== null) {
                // Reassigning copies makes the var-notify fire so the
                // displayRows binding re-evaluates.
                root.monitorRates = Object.assign({}, root.monitorRates, {
                    [m[1]]: {
                        res: m[2],
                        hz: parseFloat(m[3]),
                        scale: m[4]
                    }
                });
            }
        }
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
        width: contentColumn.width + 2 * Theme.aboutPadding
        height: contentColumn.implicitHeight + 2 * Theme.aboutPadding
        radius: Theme.pillRadius
        color: Theme.pillBackground
        border.width: 1
        border.color: Theme.highlight

        // Swallows clicks inside the card so the fullscreen catcher below
        // never sees them: the window only closes on a click OUTSIDE the
        // card. TextEdits above it still receive their own events.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: contentColumn

            // Centered inside the card: the card is sized by this column's
            // width/implicitHeight + aboutPadding on both sides, and this
            // anchor actually places the padding edges around the content.
            // Width: art column (proportional) + gap + fixed info column.
            anchors.centerIn: parent
            width: archLogoText.implicitWidth + 20 + Theme.aboutInfoWidth
            spacing: Theme.aboutRowSpacing

            // Header row: user@host title + close affordance.
            Item {
                id: headerRow

                width: parent.width
                height: aboutTitle.implicitHeight

                Text {
                    id: aboutTitle

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.userName.length > 0 ? root.userName + "@" + root.hostName : root.hostName
                    font.pixelSize: Theme.fontSize + 2
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    color: Theme.text
                }

                // Separator line under the header, fastfetch style.
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: headerRow.bottom
                    anchors.topMargin: 6
                    height: 1
                    color: Theme.highlight
                    opacity: 0.3
                }
            }

            // Logo + info block, fastfetch-like: the Arch art on the left,
            // info lines on the right; both vertically centered inside the
            // block, whose height is the larger of the two. Nothing can
            // overflow the card's measured content height.
            Item {
                id: logoBlock

                width: parent.width
                height: Math.max(archLogoText.implicitHeight, infoBlock.implicitHeight)

                readonly property real logoStep: Math.max(14, infoBlock.implicitHeight / root.archLogoLines.length)

                Text {
                    id: archLogoText

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    text: root.archLogo
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    // Stretch the art so it is exactly as tall as the info
                    // list AND keep its natural aspect: pixelSize derives
                    // from the line step using the measured JetBrainsMono
                    // line-height/pixel ratio (~1.59 in this build), so the
                    // art scales proportionally in width and height.
                    lineHeightMode: Text.FixedHeight
                    lineHeight: logoBlock.logoStep
                    font.pixelSize: Math.max(10, logoBlock.logoStep / 1.59)
                    topPadding: 30
                    rightPadding: 50
                }

                Column {
                    id: infoBlock

                    anchors {
                        left: archLogoText.right
                        leftMargin: 20
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Theme.aboutRowSpacing

                    Repeater {
                        model: root.infoRows

                        InfoRow {}
                    }
                }
            }
        }
    }

    component InfoRow: Item {
        id: row

        required property var modelData

        readonly property bool empty: modelData.value === undefined || modelData.value === null || modelData.value.length === 0

        width: parent.width
        height: visible ? Math.max(rowLabel.implicitHeight, rowText.implicitHeight) : 0
        visible: !row.empty

        // Single flowing line: "<label>: <value>" — label muted, value in
        // the normal text color right after the colon.
        Text {
            id: rowLabel

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: row.modelData.label + ":"
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: Theme.textMuted
        }

        // Editable-look-free selectable value: TextEdit (readOnly) instead
        // of Text, so users can select/copy the info; grouping/selection
        // colors come from the theme.
        TextEdit {
            id: rowText

            anchors.left: rowLabel.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            readOnly: true
            wrapMode: TextEdit.NoWrap
            selectByMouse: true
            text: row.modelData.value
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.crust
        }
    }
}
