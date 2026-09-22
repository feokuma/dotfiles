import Quickshell
import QtQuick
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
    // No WlrKeyboardFocus.Exclusive either: Hyprland routes ALL pointer
    // events to an exclusive-focus layer surface (even outside its input
    // region), which froze the bar and blocked opening another popup while
    // one was open. Popups therefore take no keyboard focus; Esc closing is
    // handled by a non-consuming global bind that calls the shell's IPC
    // (see keybindings.lua + shell.qml IpcHandler "popup").
    exclusiveZone: -1
    anchors {
        top: true
        left: true
        right: true
        bottom: true
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
