pragma Singleton
import QtQuick

// Tracks which bar popup is currently open so opening one closes any other.
// The popups (Audio/Bluetooth/Network/PowerProfiles) are independent
// fullscreen PanelWindows — without a shared coordinator they can overlap
// on screen. Popups report from open()/close(); toggle() derives from
// those, so pill clicks and click-outside catchers go through here too.
QtObject {
    id: manager

    // The popup that claimed the desktop; null when nothing is open.
    property var current: null

    function requestOpen(popup) {
        if (current && current !== popup && current.isOpen)
            current.close();
        current = popup;
    }

    function requestClose(popup) {
        if (current === popup)
            current = null;
    }
}
