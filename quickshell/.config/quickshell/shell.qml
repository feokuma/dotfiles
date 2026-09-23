//@ pragma UseQApplication
// Required by SystemTrayItem.display() / native tray menus — needs a full
// quickshell restart (not just file-watch reload) to take effect.
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "components/shell"
import "components/wallpaper"

// Global shell orchestrator.
//
// Per-monitor UI (bar, popups, launcher, About, notifications overlay) is
// declared in components/shell/ScreenShell.qml and instantiated once per
// connected screen via Variants. This file only owns truly singleton
// things: the screen Variants itself, the WallpaperPicker and the IPC
// handlers that route to the focused screen's instance.
ShellRoot {
    // One ScreenShell per connected screen.
    Variants {
        id: screenVariants

        model: Quickshell.screens
        ScreenShell {}
    }

    // The wallpaper picker is a single floating window; on toggle it is
    // pointed at the focused monitor so SUPER+W opens it where the user is.
    WallpaperPicker {
        id: wallpaperPicker
    }

    IpcHandler {
        target: "wallpaper"

        function toggleWallpaper(): void {
            const screenFor = (Hyprland.focusedMonitor?.name) ?? "";
            wallpaperPicker.screen = Quickshell.screens.find(s => s.name === screenFor)
                ?? wallpaperPicker.screen;
            wallpaperPicker.toggle();
        }
    }

    // Toggle the launcher on the focused monitor's ScreenShell instance.
    IpcHandler {
        target: "launcher"

        function toggleLauncher(): void {
            const screenName = (Hyprland.focusedMonitor?.name) ?? "";
            const inst = screenVariants.instances.find(i => i.modelData?.name === screenName)
                ?? screenVariants.instances[0];
            if (inst)
                inst.launcher.toggle();
        }
    }

    // Toggle the calendar popup on the focused monitor's instance.
    IpcHandler {
        target: "calendar"

        function toggleCalendar(): void {
            const screenName = (Hyprland.focusedMonitor?.name) ?? "";
            const inst = screenVariants.instances.find(i => i.modelData?.name === screenName)
                ?? screenVariants.instances[0];
            if (inst)
                inst.calendarPopup.toggle();
        }
    }

    // Called by the non-consuming Esc bind (see keybindings.lua). Popups and
    // the About windows take no keyboard focus, so Esc reaches the compositor
    // instead of them. No-op when nothing is open.
    IpcHandler {
        target: "popup"

        function closeActive(): void {
            for (const inst of screenVariants.instances)
                inst.closePopups();
        }
    }
}
