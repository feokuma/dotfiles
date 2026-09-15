import QtQuick
import Quickshell.Services.SystemTray
import "../../theme"
import "../../widgets"

// Tray icons inside the shared Pill container, like the other bar widgets.
// Uses the native SystemTray integration; menus are shown through
// SystemTrayItem.display(), which pops up the item's DBusMenu natively
// (submenus and checkmarks included) anchored to the bar window.
Pill {
    id: root

    // The bar window — required by display() as the anchor for the menu popup.
    property var parentWindow

    // Hidden while no app registered a tray item, so the bar
    // doesn't show an empty pill.
    visible: SystemTray.items.values.length > 0

    // A little more than the pill spacing so icons don't bleed together.
    width: trayRow.width + Theme.pillPaddingH

    Row {
        id: trayRow

        anchors.centerIn: parent
        spacing: Theme.itemSpacing

        Repeater {
            model: SystemTray.items

            TrayItem {
                parentWindow: root.parentWindow
                entry: modelData
            }
        }
    }
}
