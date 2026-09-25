pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Color picking service: Quickshell is the orchestrator, hyprpicker does
// the actual capture. No screen-picking logic lives here — the picked color
// arrives on hyprpicker's stdout and the service owns everything after it:
// recent-colors history, clipboard copy and the UI-facing signals.
//
// Why a singleton: like NotificationService, the picking flow must be
// launchable from anywhere (keybind IPC, launcher action, popup button)
// while session state (history/last color) stays shared.
//
// Root is Item (not QtObject) so it can host Process children.
Item {
    id: root

    // Newest first, max maxColors entries, session-scoped (cleared on
    // reload/restart). Persistence later: FileView, same pattern as
    // WallpaperPicker.
    readonly property var history: root._history
    property var _history: []

    // Most recently picked color (#RRGGBB), "" before the first pick.
    readonly property string currentColor: root._history.length > 0 ? root._history[0] : ""

    // True while hyprpicker owns the screen (UIs can ignore re-pick calls).
    readonly property bool picking: pickProc.running

    signal colorPicked(string hex)

    readonly property int maxColors: 5

    // Start hyprpicker. Keyboard/pointer are already ours once the popup
    // layer closed — the caller is responsible for closing UI first.
    function pick(): void {
        if (root.picking)
            return;
        pickProc.running = true;
    }

    // Copy the hex string to the Wayland clipboard. wl-copy takes the text
    // as argument and stays alive to own the paste selection; restarting
    // kills the previous owner (the already-copied data remains usable).
    function copy(hex: string): void {
        if (copyProc.running)
            copyProc.running = false;
        copyProc.command = ["wl-copy", hex];
        copyProc.running = true;
    }

    // "#CA9EE6" -> "rgb(202, 158, 230)" (row hover variant, display only).
    function toRgb(hex: string): string {
        const n = parseInt(hex.slice(1), 16);
        if (isNaN(n))
            return "";
        const r = (n >> 16) & 0xff;
        const g = (n >> 8) & 0xff;
        const b = n & 0xff;
        return "rgb(" + r + ", " + g + ", " + b + ")";
    }

    function push(hex: string): void {
        root._history = [hex].concat(root._history.filter(h => h !== hex)).slice(0, root.maxColors);
    }

    // One hyprpicker capture. The command is fixed at parse time, so a
    // later pick() simply re-triggers running (see PowerProfileService
    // note: Quickshell flips running back to false on process exit).
    //
    // -b: plain (ANSI-free) output — without it hyprpicker wraps stdout in
    //     colorized fancy output. No --autocopy: Quickshell owns the
    //     clipboard (copy()).
    // Trailing `echo`: hyprpicker 0.4.7 writes the token WITHOUT a trailing
    // newline, and SplitParser only emits on the marker (never at EOF on
    // this build) — echo supplies the missing "\n" terminator. The extra
    // empty line is ignored by the regex filter below.
    // NOTE: do NOT pass -q/--quiet on 0.4.7: with it, the picked color is
    // not printed to stdout at all (verified empirically). Any stray log
    // lines that do arrive are discarded by the regex filter.
    Process {
        id: pickProc

        command: ["sh", "-c", "hyprpicker -b; echo"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                // hyprpicker prints exactly one plain token (plus whatever
                // stray log lines); accept only a proper #hex line.
                const m = /^(#[0-9a-fA-F]{3,8})\s*$/.exec(data.trim());
                if (!m)
                    return;
                root.push(m[1]);
                root.copy(m[1]);
                root.colorPicked(m[1]);
            }
        }
        running: false
    }

    // Clipboard writer (see copy()).
    Process {
        id: copyProc

        running: false
    }
}
