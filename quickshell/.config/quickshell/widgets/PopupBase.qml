import Quickshell
import Quickshell.Wayland
import QtQuick
import "../theme"
import "../utils"

// Contract + scaffolding shared by all bar popups (Audio / Bluetooth /
// Network / PowerProfiles). QML has no interface mechanism, so inheritance
// enforces the parse: a type inheriting PopupBase can never miss the
// open/close/toggle contract or the PopupManager registration — the popup
// layer only specializes appearance/margins/layershell properties.
//
// Subclasses that need to react to state changes attach handlers to the
// `popupOpened`/`popupClosed` signals instead of overriding the functions.
PanelWindow {
    id: root

    property bool isOpen: false
    signal popupOpened
    signal popupClosed

    // Fullscreen invisible window catches every click (closes the popup)
    // while the card consumes clicks inside it. No HyprlandFocusGrab: the
    // compositor re-evaluating focus used to close popups mid-interaction.
    exclusiveZone: -1
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    // While a popup is open it owns the keyboard (same pattern as the
    // Launcher): exclusive focus lets the Escape shortcut below fire no
    // matter which app window was focused before. On close the focus goes
    // back to whatever the compositor had. We never close on focus LOSS —
    // that used to kill popups mid-interaction (see note above).
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Esc closes the popup. A window-level Shortcut (not Keys on a focused
    // item) works regardless of which control inside the popup has focus —
    // including the NetworkPopup's PSK TextField.
    Shortcut {
        sequence: "Escape"
        enabled: root.isOpen
        onActivated: root.close()
    }

    function open() {
        PopupManager.requestOpen(root);
        root.isOpen = true;
        root.popupOpened();
    }

    function close() {
        root.isOpen = false;
        PopupManager.requestClose(root);
        root.popupClosed();
    }

    function toggle() {
        root.isOpen ? root.close() : root.open();
    }
}
