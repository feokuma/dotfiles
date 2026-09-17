pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Power-profiles-daemon bridge over D-Bus (net.hadess.PowerProfiles).
//
// Why busctl + polling (documented, per AGENTS.md): there is no native
// Quickshell API for power-profiles, `powerprofilesctl` is broken on this
// machine, FileView watchChanges is unusable on sysfs (see Brightness.qml),
// and a D-Bus monitor process for PropertiesChanged would be heavier than a
// cheap 5 s refresh.
//
// Root is Item because QtObject has no default property and cannot host
// Process/Timer children.
Item {
    id: root

    // --- Public reactive state ------------------------------------------------
    // While false, the bar widget hides itself (daemon not answering).
    readonly property string profile: root._profile
    property string _profile: ""

    readonly property var profiles: root._profiles
    property var _profiles: []

    // False while the daemon is not answering (the bar widget hides itself).
    readonly property bool available: root._available
    property bool _available: false

    // Centralized Nerd Font glyph map (AGENTS.md: no scattered glyph literals).
    readonly property var glyphs: ({
        "performance": "", // nf-md-lightning_bolt
        "balanced": "", // nf-md-tune
        "power-saver": "", // nf-md-battery_saver (leaf / eco)
        "quiet": "", // nf-md-volume_low (quiet = low-noise profile)
    })
    readonly property string glyphFallback: "" // nf-md-certificate? generic power symbol

    // Resolve a profile name to its glyph, with fallback.
    function glyph(name: string): string {
        const g = root.glyphs[name];
        return g !== undefined ? g : root.glyphFallback;
    }

    // --- Reads ----------------------------------------------------------------
    // ActiveProfile: busctl prints `v s "balanced"`. Take the first quoted token.
    Process {
        id: activeProc
        command: [
            "busctl", "call", "net.hadess.PowerProfiles",
            "/org/freedesktop/UPower/PowerProfiles",
            "org.freedesktop.DBus.Properties", "Get", "ss",
            "org.freedesktop.UPower.PowerProfiles", "ActiveProfile"
        ]
        running: false
        // Quickshell 0.3.1 delivers stdout per line via SplitParser (verified
        // empirically; StdioCollector's read signal never fired on this build).
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const m = /"([^"]*)"/.exec(data);
                if (m) {
                    root._profile = m[1];
                    root._available = true;
                }
            }
        }
    }

    // Profiles: busctl prints a flattened `aa{sv}`. Each profile entry carries
    // a `s "<name>"` value right after the "Profile" dict key; grab those.
    Process {
        id: profilesProc
        command: [
            "busctl", "call", "net.hadess.PowerProfiles",
            "/org/freedesktop/UPower/PowerProfiles",
            "org.freedesktop.DBus.Properties", "Get", "ss",
            "org.freedesktop.UPower.PowerProfiles", "Profiles"
        ]
        running: false
        // Same SplitParser note as above (StdioCollector is dead on this build).
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const out = [];
                const re = /"Profile"\s+s\s+"([^"]*)"/g;
                let m;
                while ((m = re.exec(data)) !== null)
                    out.push(m[1]);
                if (out.length > 0)
                    root._profiles = out;
            }
        }
    }

    // (Re)start both reads. Quickshell flips Process.running back to false when
    // the command exits, so setting it true again cleanly re-runs each poll.
    function reload(): void {
        activeProc.running = true;
        profilesProc.running = true;
    }

    // --- Write ----------------------------------------------------------------
    function setProfile(name: string): void {
        Quickshell.execDetached([
            "busctl", "call", "net.hadess.PowerProfiles",
            "/org/freedesktop/UPower/PowerProfiles",
            "org.freedesktop.DBus.Properties", "Set", "ssv",
            "org.freedesktop.UPower.PowerProfiles", "ActiveProfile", "s", name
        ]);
        // Ask the daemon right away instead of waiting for the next poll tick.
        refreshTimer.restart();
    }

    // Short delayed re-read after a write, so sysfs/daemon has settled.
    Timer {
        id: refreshTimer
        interval: 300
        repeat: false
        onTriggered: root.reload()
    }

    // Light periodic refresh (see "Why polling" note above).
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.reload()
    }

    Component.onCompleted: root.reload()
}
