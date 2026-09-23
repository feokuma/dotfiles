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
        thumbGrid.forceActiveFocus();
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
        height: Math.min(parent.height - 160, 720)
        color: Theme.pillBackground
        radius: Theme.pillRadius
        border.width: 1
        border.color: Theme.highlight
        // Fixed card shape: the folder is local and fast, and a growing card
        // on first open reads as flicker rather than animation.
        clip: true

        opacity: root.isOpen ? 1 : 0

        readonly property int appearDuration: 160

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
                    text: "Click to apply"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.bold: Theme.fontBold
                }
            }

            GridView {
                id: thumbGrid

                // Keyboard focus lives on the grid itself; Esc closes.
                Keys.onEscapePressed: root.close()

                width: content.width - content.leftPadding - content.rightPadding
                // Header row + its gap are already part of the Column's
                // layout; the grid takes what's left inside the card.
                height: parent.height - parent.topPadding - parent.bottomPadding - content.headerHeight - content.spacing
                clip: true
                model: folderModel

                // Grid card metrics: three columns with a fixed gap; a
                // named property instead of a bare `spacing` reference so
                // the cell math never resolves against the wrong scope.
                readonly property int gridSpacing: 10
                cellWidth: (width - gridSpacing * 2) / 3
                cellHeight: Math.round(cellWidth * 0.62) // 16:10-ish card shape

                delegate: Rectangle {
                    id: thumbFrame

                    required property url fileUrl
                    required property string fileName

                    // "Current" ring: conf path vs the thumb's local path.
                    // Both sides end in the same absolute path (conf stores
                    // absolute paths written by this picker or the user).
                    readonly property string localPath: fileUrl.toString().replace("file://", "")
                    readonly property bool isCurrent: root.currentWallpaperPath !== ""
                        && localPath.endsWith(root.currentWallpaperPath.replace(/^~/, (Quickshell.env("HOME") ?? "")))

                    width: thumbGrid.cellWidth
                    height: thumbGrid.cellHeight

                    radius: Theme.pillRadius - 3
                    color: Theme.crust
                    clip: true
                    border.width: isCurrent ? 2 : hover.containsMouse ? 1 : 0
                    border.color: isCurrent ? Theme.accent : Theme.highlight

                    // Small decode buffer: bounding sourceSize keeps huge
                    // originals from ballooning memory in the thumb grid.
                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        sourceSize.width: 420
                        sourceSize.height: 264
                        source: thumbFrame.fileUrl
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                    }

                    MouseArea {
                        id: hover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.apply(thumbFrame.localPath)
                    }
                }
            }
        }
    }
}
