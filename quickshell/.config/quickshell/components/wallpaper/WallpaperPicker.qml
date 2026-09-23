import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Qt.labs.folderlistmodel
import QtQuick
import "../../theme"

// Wallpaper picker overlay: centered card with a grid of thumbnails from a
// wallpapers folder. Clicking a thumbnail applies it on the spot through
// hyprpaper's IPC (per compositor monitor) and rewrites the `path` line in
// hyprpaper.conf, so the choice survives relogin. Opened by the "wallpaper"
// IPC (SUPER + W, see keybindings.lua).
//
// Not a PopupBase subclass: unlike the bar popups it takes keyboard focus
// (own Esc handling) and is centered like the Launcher, not bar-anchored.
PanelWindow {
    id: root

    property bool isOpen: false

    // Collection folder (absolute; FolderListModel does not expand tilde).
    property string wallpaperDir: (Quickshell.env("HOME") ?? "") + "/Pictures/Wallpapers"

    // hyprpaper owns the wallpaper; the conf rewrite happens after apply.
    property string hyprpaperConf: (Quickshell.env("HOME") ?? "") + "/.config/hypr/hyprpaper.conf"

    // Path currently configured in hyprpaper.conf, refreshed on open; used
    // to ring the active thumbnail ("current" marker).
    property string currentWallpaperPath: ""

    // Non-empty while an image is being applied (preload -> wallpaper chain).
    property string pendingPath: ""

    readonly property var imageExtensions: ["*.png", "*.jpg", "*.jpeg", "*.webp"]

    function apply(path) {
        root.pendingPath = path;
        // hyprpaper's `wallpaper` refuses a path that was never preloaded in
        // this daemon run, so the preload must complete first (chained via
        // onExited on preloadProcess) — no shell layer needed.
        preloadProcess.command = ["hyprctl", "hyprpaper", "preload", path];
        preloadProcess.running = true;
    }

    function persist(path) {
        // Rewrite only the `path =` line inside the first wallpaper block.
        // sed in-place instead of FileView's writeAdapter: this quickshell
        // build ships no text adapter, only JsonAdapter.
        sedProcess.command = [
            "sed", "-i", "-E",
            "s|^path[[:space:]]*=.*|path    = " + path + "|",
            root.hyprpaperConf,
        ];
        sedProcess.running = true;
    }

    function notify(path) {
        // Ack via the shell's own notification daemon (Quickshell owns the
        // DBus server): notify-send lands in the Cards top-right stack.
        const name = path.split("/").pop();
        Quickshell.execDetached({ command: ["notify-send", "-a", "Wallpaper", "Wallpaper applied", name] });
    }

    function refreshCurrentPath() {
        // Tolerate cold open: an unloaded conf yields "" (no ring that
        // time); the `loaded` signal refreshes it as soon as it arrives.
        const text = hyprpaperConfView.text() ?? "";
        const match = text.match(/path\s*=\s*([^\n]+)/);
        root.currentWallpaperPath = match ? match[1].trim() : "";
    }

    function open() {
        refreshCurrentPath();
        root.isOpen = true;
        carousel.forceActiveFocus();
    }

    function close() {
        root.isOpen = false;
    }

    function toggle() {
        root.isOpen ? root.close() : root.open();
    }

    visible: root.isOpen
    color: "transparent"
    // An overlay must not reserve screen space.
    exclusiveZone: -1

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:wallpaper"
    // Like the Launcher: the surface owns keyboard focus while open (for the
    // grid's Esc) and hands it back on close.
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Process {
        id: preloadProcess

        onExited: {
            // Apply to every monitor the compositor reports right now —
            // no eDP-1 hard-coding.
            const path = root.pendingPath;
            const monitors = Hyprland.monitors.values;
            for (let i = 0; i < monitors.length; i++) {
                Quickshell.execDetached({
                    command: ["hyprctl", "hyprpaper", "wallpaper", monitors[i].name + "," + path],
                });
            }
            root.persist(path);
            root.notify(path);
            root.currentWallpaperPath = path;
            root.pendingPath = "";
            root.close();
        }
    }

    Process {
        id: sedProcess
    }

    FileView {
        id: hyprpaperConfView

        path: root.hyprpaperConf
        preload: true
        watchChanges: false

        // The ring may precede the async conf read on the very first open.
        onLoaded: root.refreshCurrentPath()
    }

    FolderListModel {
        id: folderModel

        folder: "file://" + root.wallpaperDir
        nameFilters: root.imageExtensions
        showDirs: false
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent
        width: Math.min(Math.max(parent.width * 0.5, 640), 960)
        // Inner width seen by content children: Column margins (2+2) plus
        // the Column's own l/r paddings (14+14).
        readonly property int innerWidth: width - 32
        // Height hugs the centered disc: paddings + header + gap + carousel.
        // 1.05x headroom: the side fan sits lower/smaller, so only a thin
        // margin is needed before clipping.
        height: content.topPadding
            + content.bottomPadding
            + content.headerHeight
            + content.spacing
            + innerWidth * 0.52 * 0.62 * 1.05
        color: Theme.pillBackground
        radius: Theme.pillRadius
        border.width: 1
        border.color: Theme.highlight
        // No outer clip: discs may pass the interior clip edge freely, but a
        // dedicated clip item below keeps them off the border line.

        opacity: root.isOpen ? 1 : 0

        readonly property int appearDuration: 160

        Behavior on opacity {
            NumberAnimation {
                duration: panel.appearDuration
                easing.type: Easing.OutCubic
            }
        }

        // Interior clip: cuts overflowing carousel discs 1px inside the frame
        // so the border line always stays visible (the panel itself cannot
        // clip without the discs painting over its own border).
        Item {
            id: clipBox

            anchors.fill: parent
            anchors.margins: 1
            clip: true

            Column {
                id: content

            anchors.fill: parent
            anchors.margins: 2
            topPadding: 12
            leftPadding: 14
            rightPadding: 14
            bottomPadding: 12
            spacing: 8

            // Header metrics pinned here so the grid's height math stays
            // simple and the Column never queries its children.
            readonly property int headerHeight: Theme.pillHeight

            // Header: title left, hint right.
            Item {
                width: content.width - content.leftPadding - content.rightPadding
                height: content.headerHeight

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wallpaper"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: Theme.fontBold
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "←/→ select · Enter/click apply · Esc close"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.bold: Theme.fontBold
                }
            }

            // Carousel (iTunes "Cover Flow" style): the selected thumbnail
            // sits centered and scaled up; neighbors recede to the sides.
            // A Repeater with explicit per-offset geometry instead of
            // PathView: the collection is small, deterministic placement is
            // easy to reason about, and no flick physics is wanted here.
            Item {
                id: carousel

                // Keyboard focus lives on the carousel; arrows move the
                // selection, Enter applies it, Esc closes.
                Keys.onEscapePressed: root.close()
                Keys.onLeftPressed: carousel.selectPrevious()
                Keys.onRightPressed: carousel.selectNext()
                Keys.onReturnPressed: carousel.applySelected()
                Keys.onEnterPressed: carousel.applySelected()

                width: content.width - content.leftPadding - content.rightPadding
                // Header row + its gap are already part of the Column's
                // layout; the carousel takes what's left inside the card.
                height: parent.height - parent.topPadding - parent.bottomPadding - content.headerHeight - content.spacing
                clip: false // scaled discs must be allowed to overflow slightly

                // Background wheel/snap surface: two-finger touchpad swipes
                // arrive here as scroll axis events, nudging the selection
                // exactly like the compositor's 3-finger workspace swipe.
                // The whole carousel area is the gesture zone; disc clicks
                // still win because child MouseAreas sit above this one.
                MouseArea {
                    id: swipeSurface

                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton // clicks must reach the discs
                    hoverEnabled: false
                    onWheel: (wheel) => carousel.feedSwipe(wheel.angleDelta.y)
                }

                // Selected (centered) disc; defaults to the current wallpaper
                // so the picker opens on what's already applied.
                property int selectedIndex: 0
                property bool initialized: false

                readonly property int count: folderModel.count

                // Geometry ramp per |offset| from the center disc (index
                // 0 = center). Anything past the visible fan fades out.
                // Cover Flow feel: nearest neighbors large and close, then
                // the row flattens out.
                readonly property real centerScale: 1.0
                readonly property real sideScale: 0.62
                readonly property real farScale: 0.45

                function selectNext() {
                    if (carousel.selectedIndex < carousel.count - 1)
                        carousel.selectedIndex += 1;
                }

                function selectPrevious() {
                    if (carousel.selectedIndex > 0)
                        carousel.selectedIndex -= 1;
                }

                function applySelected() {
                    const path = carousel.paths[carousel.selectedIndex];
                    if (path)
                        root.apply(path);
                }

                // Two-finger swipe accumulator. Up/natural-scroll-forward
                // (positive delta) moves to the next wallpaper on the right,
                // mirroring the compositor gesture direction. One step per
                // wheel-notch: a flick may emit several events, so the
                // leftover delta carries over between steps.
                property real swipeAccum: 0

                function feedSwipe(delta) {
                    // A short pause between wheel bursts resets the ramp, so
                    // two separate swipes never double-step.
                    const now = Date.now();
                    if (now - carousel.lastSwipeAt > 250)
                        carousel.swipeAccum = 0;
                    carousel.lastSwipeAt = now;

                    carousel.swipeAccum += delta;
                    while (carousel.swipeAccum >= 120) {
                        carousel.selectNext();
                        carousel.swipeAccum -= 120;
                    }
                    while (carousel.swipeAccum <= -120) {
                        carousel.selectPrevious();
                        carousel.swipeAccum += 120;
                    }
                }

                property real lastSwipeAt: 0

                // Local paths reported by the delegates as they resolve; the
                // model supports no direct `get()`, so this suffices.
                property var paths: ([])

                // Offset-dependent geometry — one chart, both sides sign-flipped.
                readonly property int visualRange: 2 // discs shown per side

                function xFor(offset) {
                    // Fan-out spacing: near discs closer than edge discs.
                    const mag = Math.min(Math.abs(offset), carousel.visualRange);
                    const step = mag === 0 ? 0
                        : mag === 1 ? carousel.width * 0.34
                        : carousel.width * 0.46;
                    return carousel.width / 2 + Math.sign(offset) * step;
                }

                function scaleFor(offset) {
                    const mag = Math.min(Math.abs(offset), carousel.visualRange);
                    return mag === 0 ? carousel.centerScale
                        : mag === 1 ? carousel.sideScale
                        : carousel.farScale;
                }

                function yFor(offset) {
                    // Laterals sit a touch lower, like the iTunes stack.
                    const mag = Math.min(Math.abs(offset), carousel.visualRange);
                    return mag === 0 ? 0 : mag === 1 ? 14 : 26;
                }

                function opacityFor(offset) {
                    const mag = Math.abs(offset);
                    return mag > carousel.visualRange ? 0
                        : mag === 0 ? 1.0
                        : mag === 1 ? 0.9
                        : 0.55;
                }

                Repeater {
                    model: folderModel

                    delegate: Item {
                        id: disc

                        required property url fileUrl
                        required property string fileName
                        required property int index

                        // Signed distance from the selected disc.
                        readonly property int offset: index - carousel.selectedIndex

                        readonly property string localPath: fileUrl.toString().replace("file://", "")
                        readonly property bool isSelected: offset === 0
                        readonly property bool isApplied: root.currentWallpaperPath !== ""
                            && localPath.endsWith(root.currentWallpaperPath.replace(/^~/, (Quickshell.env("HOME") ?? "")))

                        // Register the resolved local path (no model get())
                        // and center the applied wallpaper on first open.
                        Component.onCompleted: {
                            carousel.paths[index] = localPath;
                            if (!carousel.initialized && isApplied) {
                                carousel.selectedIndex = index;
                                carousel.initialized = true;
                            }
                        }

                        width: carousel.width * 0.52
                        height: width * 0.62

                        // iTunes-style geometry, animated so a selection
                        // change slides the whole fan smoothly.
                        x: carousel.xFor(offset) - disc.width / 2
                        y: parent.height / 2 - disc.height / 2 + carousel.yFor(offset)
                        z: 20 - Math.min(Math.abs(offset), 10) * 2
                        scale: carousel.scaleFor(offset)
                        opacity: carousel.opacityFor(offset)

                        Behavior on x {
                            NumberAnimation {
                                duration: Theme.animSlow
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on y {
                            NumberAnimation {
                                duration: Theme.animSlow
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.animSlow
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animSlow
                            }
                        }

                        Rectangle {
                            id: frame

                            anchors.fill: parent
                            radius: Theme.pillRadius - 3
                            color: Theme.crust
                            clip: true
                            border.width: isApplied ? 2 : disc.isSelected ? 2 : hover.containsMouse ? 1 : 0
                            border.color: isApplied ? Theme.accent : Theme.highlight

                            // Small decode buffer: bounding sourceSize keeps
                            // huge originals from ballooning memory.
                            Image {
                                anchors.fill: parent
                                anchors.margins: 1
                                sourceSize.width: 640
                                sourceSize.height: 400
                                source: disc.fileUrl
                                asynchronous: true
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                            }

                            MouseArea {
                                id: hover

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                // Faded-out fan edge must not swallow hover
                                // or clicks aimed at the swipe surface.
                                enabled: Math.abs(disc.offset) <= carousel.visualRange
                                onClicked: {
                                    if (disc.isSelected)
                                        root.apply(disc.localPath);
                                    else
                                        carousel.selectedIndex = disc.index;
                                }
                            }
                        }
                    }
                }
            }
            }
        }
    }
}
