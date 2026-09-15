import QtQuick
import QtQuick.Controls
import Quickshell.Widgets
import "../../theme"

// One tray entry: icon + click/wheel interactions + tooltip.
// display() coordinates are relative to the bar window's content space,
// so the icon position is mapped through mapToItem(null, ...) as
// mapToItem(null) resolves to the root item (= window content origin).
MouseArea {
    id: root

    // SystemTrayItem from the parent Repeater (context property, not required
    // property — required modelData on a standalone component root is fragile).
    property var entry
    // Bar window, forwarded by Tray for menu anchoring.
    property var parentWindow

    // Sized to the icon so centered anchoring is loop-free.
    width: Theme.trayIconSize
    height: Theme.trayIconSize
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton && !entry.onlyMenu) {
            entry.activate();
        } else {
            showMenu();
        }
    }

    onWheel: wheel => {
        entry.scroll(wheel.angleDelta.y > 0 ? 1 : -1, false);
    }

    function showMenu() {
        const pos = root.mapToItem(null, 0, 0);
        entry.display(root.parentWindow, pos.x, pos.y);
    }

    IconImage {
        id: icon

        anchors.centerIn: parent
        implicitSize: Theme.trayIconSize
        source: root.entry?.icon ?? ""
        // Slightly dimmed at rest, full brightness while hovered.
        opacity: root.containsMouse ? 1 : 0.8
    }

    ToolTip.visible: root.containsMouse && root.entry
    ToolTip.delay: 400
    ToolTip.text: root.entry?.tooltipTitle || root.entry?.title || ""
}
