import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../../theme"

// Application launcher overlay, Wofi-like look:
// near-opaque dark panel, flat full-width rows, subtle selection highlight.
//
// Lives insid the running shell instance: open/close only toggles the
// window's visibility; Hyprland triggers it through the shell's IpcHandler
// (see shell.qml, target "launcher").
PanelWindow {
    id: root

    property bool isOpen: false
    property string search: ""
    property int selectedIndex: 0
    property int fontSize: Theme.fontSize + 10

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

    // Container without its own background — a Rectangle would paint white
    // by default and leak through the rounded corners (same reason Pill.qml
    // uses a plain Item).
    Item {
        id: panel

        // Fixed vertical position, advancing downward as results appear.
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 400
        width: 850
        height: content.implicitHeight

        // Background only — same tokens as the bar pills. Opacity must be
        // confined to this rect, otherwise the whole overlay washes out.
        Rectangle {
            anchors.fill: parent
            color: Theme.pillBackground
            //opacity: Theme.pillOpacity
            radius: Theme.pillRadius
        }

        Column {
            id: content

            anchors.fill: parent
            leftPadding: 16
            rightPadding: 16
            spacing: 6

            // Search field
            Item {
                width: parent.width - parent.leftPadding - parent.rightPadding
                height: 82

                Row {
                    anchors.fill: parent
                    leftPadding: 6
                    topPadding: 30
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

                readonly property int rowHeight: 42

                width: content.width - content.leftPadding - content.rightPadding
                // Cap at a whole number of rows, so no item is ever clipped
                // at the bottom edge of the panel.
                height: Math.min(contentHeight, Math.floor(340 / rowHeight) * rowHeight)
                clip: true
                model: root.results
                currentIndex: root.selectedIndex

                delegate: Rectangle {
                    width: resultList.width
                    height: resultList.rowHeight
                    radius: 6
                    // Flat Wofi-style highlight: translucent accent wash,
                    // same treatment for hover and selection.
                    color: Theme.textMuted
                    opacity: model.index === root.selectedIndex ? 0.3 : (hoverArea.containsMouse ? 0.15 : 0)

                    MouseArea {
                        id: hoverArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launch(model.index)
                    }

                    Row {
                        anchors.fill: parent
                        leftPadding: 10
                        spacing: 10

                        // Real desktop-entry icon resolved through the icon
                        // theme (IconImage needs a URL, not an icon name),
                        // with a safe generic fallback.
                        IconImage {
                            id: appIcon

                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 20
                            source: Quickshell.iconPath(modelData.icon, "application-x-executable")
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
