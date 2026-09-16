import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../../theme"

// Application launcher overlay, macOS Spotlight-like look:
// near-opaque dark panel, tall rows with crisp icons, and a rounded
// accent selection bar drawn behind the row content.
//
// Lives inside the running shell instance: open/close only toggles the
// window's visibility; Hyprland triggers it through the shell's IpcHandler
// (see shell.qml, target "launcher").
PanelWindow {
    id: root

    property bool isOpen: false
    property string search: ""
    property int selectedIndex: 0
    property int fontSize: Theme.fontSize + 10

    // Spotlight-style highlight intensities, derived locally: only the
    // launcher selection bar uses these, so they don't warrant Theme tokens.
    readonly property real highlightSelectedOpacity: 0.35
    readonly property real highlightHoverOpacity: 0.18
    // Short fade keeps the bar feeling snappy instead of laggy.
    readonly property int highlightDuration: 120

    // Entrance timeline shared by the panel and the result rows, so list
    // growth and row animation feel like one motion.
    readonly property int rowAppearDuration: 160

    // Case-insensitive substring filter over name, generic name and keywords.
    // Desktop entries come from Quickshell's native DesktopEntries API.
    readonly property var results: {
        const query = root.search.toLowerCase();
        const apps = DesktopEntries.applications.values;
        const out = [];
        for (let i = 0; i < apps.length; i++) {
            const app = apps[i];
            if (app.noDisplay)
                continue;
            if (query === "")
                return out; // show nothing until the user starts typing
            const haystack = (app.name + "\n" + app.genericName + "\n" + app.keywords.join("\n")).toLowerCase();
            if (haystack.includes(query))
                out.push(app);
        }
        out.sort((a, b) => a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1);
        return out;
    }

    // Keep the selection valid: if a change invalidated it, fall back to the first result.
    onResultsChanged: {
        if (root.selectedIndex >= root.results.length)
            root.selectedIndex = 0;
    }

    function open() {
        root.search = "";
        searchInput.clear();
        root.selectedIndex = 0;
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
        root.search = "";
        searchInput.clear();
    }

    function toggle() {
        root.isOpen ? root.close() : root.open();
    }

    function selectNext() {
        if (root.selectedIndex < root.results.length - 1) {
            root.selectedIndex += 1;
            resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
        }
    }

    function selectPrevious() {
        if (root.selectedIndex > 0) {
            root.selectedIndex -= 1;
            resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
        }
    }

    function launch(index) {
        const app = root.results[index];
        if (!app)
            return;
        root.close();
        app.execute();
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
    WlrLayershell.namespace: "quickshell:launcher"
    // Take the keyboard away from apps while the launcher is open and hand
    // it back on close. Native layer-shell focus, no hacks.
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onIsOpenChanged: {
        // forceActiveFocus only sticks once the surface is mapped.
        if (root.isOpen)
            searchInput.forceActiveFocus();
    }

    // Single visual container: background, border and content live in the
    // same Rectangle, so one entrance animation and one growth animation
    // drive everything — the rows are clipped by the panel and revealed as
    // it grows, never painted ahead of their own background.
    Rectangle {
        id: panel

        // Fixed vertical position, advancing downward as results appear.
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 400
        width: 850

        // Same tokens as the bar pills. Opacity must be confined to this
        // rect, otherwise the whole overlay washes out.
        color: Theme.pillBackground
        radius: Theme.pillRadius
        border.width: 1
        border.color: Theme.highlight
        // Nothing paints outside the rounded frame: the list shrinks/grows
        // inside the clip, so background and rows always appear together.
        clip: true

        // Border margin enters implicitHeight via content margins; paddings
        // are part of the Column's own implicitHeight.
        height: content.implicitHeight + content.anchors.margins * 2

        // Follow result growth/shrink smoothly instead of jumping to a new
        // size on the first keystroke.
        Behavior on height {
            NumberAnimation {
                duration: root.rowAppearDuration
                easing.type: Easing.OutCubic
            }
        }

        // Soft entrance: quick fade plus a short slide-up. Driven by isOpen,
        // so the same values gently reverse if the window ever outlives a
        // close (the instant hide makes the reverse animation invisible).
        readonly property int appearDuration: 160

        opacity: root.isOpen ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: panel.appearDuration
                easing.type: Easing.OutCubic
            }
        }

        transform: Translate {
            y: root.isOpen ? 0 : 14

            Behavior on y {
                NumberAnimation {
                    duration: panel.appearDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        Column {
            id: content

            anchors.fill: parent
            // Clear the 1px border on every side.
            anchors.margins: 2
            // Asymmetric comfort: slightly more above the search than below
            // the list, matching the Spotlight layout.
            topPadding: 10
            leftPadding: 16
            rightPadding: 16
            bottomPadding: 8
            spacing: 6

            // Search field. Compact while idle, so the empty panel is just
            // the field and the input looks vertically centered; the extra
            // breathing room above the results comes from the Column
            // paddings, not from this field.
            Item {
                width: parent.width - parent.leftPadding - parent.rightPadding
                height: 60

                Row {
                    anchors.fill: parent
                    leftPadding: 6
                    spacing: 10

                    Text {
                        id: searchIcon

                        anchors.verticalCenter: parent.verticalCenter
                        text: "\ueb82" // nf-md-magnify
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: root.fontSize
                        font.bold: Theme.fontBold
                    }

                    TextInput {
                        id: searchInput

                        width: parent.width - searchIcon.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: root.fontSize
                        font.bold: Theme.fontBold
                        cursorVisible: root.isOpen
                        clip: true
                        onTextChanged: root.search = text
                        Keys.onEscapePressed: root.close()
                        Keys.onEnterPressed: root.launch(root.selectedIndex)
                        Keys.onReturnPressed: root.launch(root.selectedIndex)
                        Keys.onDownPressed: root.selectNext()
                        Keys.onUpPressed: root.selectPrevious()

                        Text {
                            visible: searchInput.text === ""
                            text: "Search applications..."
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: root.fontSize
                            font.bold: Theme.fontBold
                        }
                    }
                }
            }

            // Results; height is capped, excess results scroll.
            ListView {
                id: resultList

                // Generous Spotlight row: tall enough for a 30px icon with
                // comfortable breathing room.
                readonly property int rowHeight: 48

                width: content.width - content.leftPadding - content.rightPadding
                // Cap at a whole number of rows, so no item is ever clipped
                // at the bottom edge of the panel.
                height: Math.min(contentHeight, Math.floor(340 / rowHeight) * rowHeight)
                clip: true
                model: root.results
                currentIndex: root.selectedIndex

                // Rows fade in with a short slide-up, rippling by index so
                // the list feels like it cascades instead of popping. The
                // model is rebuilt on every keystroke, so durations stay
                // short: anything longer would make typing feel laggy.
                add: Transition {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: ViewTransition.target.appearDelay
                        }
                        NumberAnimation {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: root.rowAppearDuration
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            property: "y"
                            from: ViewTransition.target.y + 14
                            to: ViewTransition.target.y
                            duration: root.rowAppearDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                // Rows below a newly inserted one follow their new position
                // with the same timeline as the fade.
                displaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: root.rowAppearDuration
                        easing.type: Easing.OutCubic
                    }
                }

                delegate: Item {
                    id: row

                    width: resultList.width
                    height: resultList.rowHeight

                    // Cascade delay: each row waits a little longer than the
                    // one above it, capped so long lists don't feel slow.
                    readonly property int appearDelay: Math.min(model.index * 25, 150)

                    // Selection/hover bar drawn *behind* the row content, so
                    // icon and name keep full legibility. Dark text stays
                    // readable on the light highlight bar. Opacity stays on
                    // this rect only — on the row parent it would wash out
                    // the children too.
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.pillRadius
                        color: Theme.highlight
                        opacity: model.index === root.selectedIndex
                                 ? root.highlightSelectedOpacity
                                 : (hoverArea.containsMouse ? root.highlightHoverOpacity : 0)

                        Behavior on opacity {
                            NumberAnimation { duration: root.highlightDuration }
                        }
                    }

                    MouseArea {
                        id: hoverArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launch(model.index)
                    }

                    Row {
                        anchors.fill: parent
                        // Spotlight padding: 16 on the left, 14 between icon
                        // and name.
                        leftPadding: 16
                        spacing: 14

                        // Real desktop-entry icon resolved through the icon
                        // theme (IconImage needs a URL, not an icon name),
                        // with a safe generic fallback.
                        IconImage {
                            id: appIcon

                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 30
                            source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                            // IconImage wraps a QtQuick.Image; smooth scaling
                            // lives on the backing image (defaults to true,
                            // kept explicit for crisp upscaling under
                            // fractional scaling).
                            backer.smooth: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: root.fontSize
                            font.bold: Theme.fontBold
                            elide: Text.ElideRight
                            width: parent.width - parent.leftPadding - appIcon.width - parent.spacing
                        }
                    }
                }
            }

            // Empty state (only makes sense while actually searching)
            Text {
                visible: root.search !== "" && root.results.length === 0
                text: "No applications found"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: root.fontSize
                font.bold: Theme.fontBold
                horizontalAlignment: Text.AlignHCenter
                leftPadding: (content.width - content.leftPadding - content.rightPadding - Text.implicitWidth) / 2
            }
        }
    }
}
