# AGENTS.md

## Project goal

Build a clean, modular Arch Linux desktop based on:

- **Hyprland** as the Wayland compositor/window manager.
- **Lua** for Hyprland configuration.
- **Quickshell** for desktop-shell utilities and UI.
- **Ghostty** as the terminal.
- **Zsh + Starship** for the interactive shell/prompt.
- **greetd + tuigreet** for login/session startup.
- **Git-managed dotfiles** for user configuration.
- **Snapper** for manual system snapshots.

The desktop should be built incrementally. Prefer small, understandable components over large preconfigured desktop environments or opaque frameworks.

The long-term objective is for Quickshell to provide most desktop-shell functionality such as the panel, workspaces UI, clock, system tray, audio/brightness controls, networking, Bluetooth, notifications, launcher, OSDs, and power menu.

---

## General principles

1. **Keep the system minimal.**
   - Do not add packages just because they are common in Hyprland setups.
   - Add a dependency only when a concrete feature requires it.
   - Prefer packages from Arch official repositories when available.
   - Do not add AUR packages unless there is a clear reason.

2. **Prefer native Wayland solutions.**
   - Avoid X11-only tools when a good Wayland-native alternative exists.
   - XWayland may remain installed for application compatibility.

3. **Do not silently change the system.**
   - Changes under the user's home directory may be proposed and implemented when directly related to the current task.
   - Before installing/removing packages, enabling/disabling system services, changing `/etc`, modifying boot configuration, Btrfs layout, Snapper configuration, PAM, greetd, or other system-wide configuration, explain the required change and ask for approval.
   - Never run destructive filesystem, package-removal, bootloader, partitioning, or Btrfs commands without explicit approval.

4. **Preserve a working desktop at every step.**
   - Changes should be incremental and easy to revert.
   - Avoid large rewrites unless specifically requested.
   - Prefer one focused change per commit.

5. **Do not introduce duplicate desktop components.**
   Unless explicitly requested, do not install or configure replacements for functionality intended to be built in Quickshell, including:
   - Waybar
   - Wofi
   - Rofi
   - SwayNC
   - Mako
   - Dunst
   - wlogout

6. **Use existing dedicated components when appropriate.**
   Quickshell does not need to replace everything immediately.
   - Keep `greetd + tuigreet` for login unless asked to build a Quickshell greeter.
   - `hyprlock` and `hypridle` may be introduced later for locking and idle management.
   - Do not replace stable infrastructure merely for aesthetic consistency.

---

# Hyprland

## Configuration format

This setup uses the modern **Lua configuration format**.

Primary file:

```text
~/.config/hypr/hyprland.lua
```

Do not create or migrate configuration back to legacy `hyprland.conf` / hyprlang syntax.

Use the current Hyprland Lua API such as:

```lua
hl.config(...)
hl.monitor(...)
hl.bind(...)
hl.env(...)
hl.dsp.*
```

Do not assume old Hyprland syntax or old dispatcher names are valid.

When uncertain about an API, check the current official Hyprland documentation before implementing it.

Official documentation:

```text
https://wiki.hypr.land/
```

## Modular configuration

Prefer splitting the Hyprland configuration into focused Lua modules.

Recommended structure:

```text
hypr/
├── hyprland.lua
├── monitors.lua
├── input.lua
├── environment.lua
├── appearance.lua
├── animations.lua
├── keybindings.lua
├── windowrules.lua
└── autostart.lua
```

`hyprland.lua` should primarily orchestrate configuration:

```lua
require("monitors")
require("input")
require("environment")
require("appearance")
require("animations")
require("windowrules")
require("keybindings")
require("autostart")
```

Keep each file focused on one responsibility.

Hyprland's Lua `require()` support should be preferred over manually concatenating configuration files.

## Current machine assumptions

Current internal display:

```text
eDP-1
2880x1800
120 Hz
```

Fractional scaling may be used. Do not hard-code assumptions about external monitors.

When adding monitor logic:

- Handle the built-in panel cleanly.
- Avoid breaking startup when an external monitor is absent.
- Prefer monitor rules that remain usable when docking/undocking.

## Input

Current preferred keyboard layout:

```text
us
intl
```

Keyboard remapping may be handled outside Hyprland when appropriate (for example with `keyd`). Do not duplicate low-level remapping in Hyprland unless explicitly requested.

Touchpad defaults should favor laptop use, including natural scrolling when requested.

Do not introduce aggressive touchpad tuning without testing.

## Keybindings

Keep keybindings centralized in `keybindings.lua`.

Prefer semantic organization:

```lua
-- Applications
-- Window management
-- Focus
-- Workspaces
-- Media
-- Screenshots
-- Quickshell actions
-- Session / power
```

Use the current Lua dispatcher API.

Example style:

```lua
hl.bind({ "SUPER", "Return", function()
    hl.dsp.exec_cmd("ghostty")
end })
```

Do not convert working `hl.dsp.*` calls to shell commands unless necessary.

When executing external programs:

- Prefer `hl.dsp.exec_raw()` when no shell expansion is required.
- Prefer `hl.dsp.exec_cmd()` when shell behavior is intentionally required.
- Avoid unnecessary `sh -c` / `bash -c` layers.

For quitting Hyprland, prefer the recommended graceful shutdown mechanism rather than directly invoking the compositor exit dispatcher when possible.

## Autostart

Keep autostart minimal.

Do not launch services from Hyprland that should be managed by systemd user services.

Examples of things that generally should not be repeatedly started manually from Hyprland:

- PipeWire
- pipewire-pulse
- WirePlumber
- long-running user services already managed by systemd

Quickshell itself may be launched from Hyprland unless/until a cleaner user-service strategy is intentionally introduced.

## Environment variables

Keep environment-specific configuration centralized.

Do not scatter environment variables across several Lua files.

Before adding compatibility workarounds such as:

```text
WLR_NO_HARDWARE_CURSORS
```

verify that the current hardware actually requires them.

Do not carry forward workarounds from previous installations without evidence.

---

# Quickshell

## Purpose

Quickshell is the primary desktop-shell toolkit for this project.

It should progressively provide:

1. Panel/bar
2. Workspace indicator
3. Clock/date
4. System tray
5. Audio controls
6. Brightness controls
7. Battery status
8. Network status and controls
9. Bluetooth status and controls
10. Media controls
11. Notification daemon/UI
12. Application launcher
13. OSDs
14. Power/session menu
15. Optional lock/login UI later

Do not attempt to build all of these at once.

Implement and validate one subsystem at a time.

Official documentation:

```text
https://quickshell.org/docs/
```

Use the documentation matching the locally installed Quickshell version whenever APIs differ between versions.

## Architecture

Prefer a component/service separation.

Suggested structure:

```text
quickshell/
├── shell.qml
├── components/
│   ├── bar/
│   │   ├── Bar.qml
│   │   ├── Workspaces.qml
│   │   ├── Clock.qml
│   │   ├── Tray.qml
│   │   └── StatusArea.qml
│   ├── notifications/
│   ├── launcher/
│   ├── osd/
│   └── power/
├── services/
│   ├── AudioService.qml
│   ├── BrightnessService.qml
│   ├── NetworkService.qml
│   ├── BluetoothService.qml
│   ├── MediaService.qml
│   └── NotificationService.qml
├── widgets/
│   ├── IconButton.qml
│   ├── TextButton.qml
│   └── Popup.qml
└── theme/
    ├── Theme.qml
    ├── Colors.qml
    ├── Typography.qml
    └── Metrics.qml
```

This is a guideline, not a requirement. Do not create empty abstraction layers before they are useful.

## QML design rules

Prefer:

- small components;
- explicit properties;
- declarative bindings;
- reusable primitives;
- clear state ownership;
- minimal imperative JavaScript;
- Qt/Quickshell APIs instead of shelling out to CLI tools.

Avoid:

- giant `shell.qml` files;
- duplicated state;
- global mutable properties;
- polling when reactive APIs/signals are available;
- `Process` calls for information already exposed by Quickshell APIs;
- hard-coded screen dimensions;
- deeply nested logic inside visual components.

## Built-in Quickshell integrations

Prefer Quickshell's native integrations where available.

Relevant modules include:

```text
Quickshell.Hyprland
Quickshell.Bluetooth
Quickshell.Networking
Quickshell.Services.Pipewire
Quickshell.Services.Mpris
Quickshell.Services.Notifications
Quickshell.Services.SystemTray
Quickshell.Services.UPower
Quickshell.Wayland
```

Availability depends on the installed Quickshell version.

Before implementing a service by spawning commands such as `hyprctl`, `wpctl`, `nmcli`, `bluetoothctl`, or similar, check whether Quickshell already exposes the required information or action directly.

CLI processes are acceptable when a native API is unavailable or clearly insufficient.

## Hyprland integration

Use `Quickshell.Hyprland` for workspace/window/compositor information where practical.

Avoid polling `hyprctl` for continuously changing state if Quickshell provides reactive Hyprland objects or events.

Hyprland keybindings may invoke Quickshell IPC/actions when appropriate instead of spawning duplicate UI processes.

## Multi-monitor behavior

All major shell UI must eventually support multiple screens.

Do not assume only `eDP-1` exists in Quickshell UI code.

For panels/windows that belong on every monitor, prefer Quickshell's screen model / variants approach rather than manually duplicating monitor names.

Laptop-only assumptions are acceptable only for hardware-specific controls such as internal display brightness.

## Panel

Start with a simple panel before adding popups.

Recommended progression:

```text
PanelWindow
  ↓
Clock
  ↓
Workspaces
  ↓
Battery
  ↓
Audio
  ↓
Tray
  ↓
Network/Bluetooth
```

The panel should support transparency and should not hard-code visual positioning that breaks with different resolutions/scales.

## Theme

Centralize visual tokens.

Do not hard-code colors throughout individual components.

Prefer:

```qml
Theme.background
Theme.surface
Theme.text
Theme.accent
Theme.warning
Theme.error
Theme.radiusSmall
Theme.radiusMedium
Theme.spacingSmall
Theme.spacingMedium
```

A Catppuccin-inspired palette is acceptable, but components should reference semantic theme values rather than raw palette values.

Similarly centralize:

- font families;
- font sizes;
- border radius;
- spacing;
- animation durations;
- opacity levels.

## Fonts and icons

Current terminal setup uses a Nerd Font.

For Quickshell, do not assume glyph icons are the only option.

Prefer, in order:

1. symbolic/system icons when appropriate;
2. SVG/icon assets with explicit ownership;
3. Nerd Font glyphs for simple lightweight indicators.

Do not scatter Unicode icon literals throughout the codebase. Put them in a centralized icon mapping if heavily used.

## Notifications

When implementing notifications, use Quickshell's notification APIs rather than running an external notification daemon.

Only one notification daemon should own the desktop notification service.

The notification UI should eventually support:

- title/app name;
- body;
- icon/image where available;
- timeout;
- actions where supported;
- history/persistence only if deliberately designed.

Do not add SwayNC, Mako, or Dunst as a parallel notification daemon unless explicitly requested.

## System tray

Use Quickshell's SystemTray integration.

Do not recreate tray state by inspecting processes.

Menus should use the tray item's DBusMenu integration where available.

## Audio

Prefer Quickshell's PipeWire integration.

The system uses the PipeWire audio stack.

Do not add PulseAudio daemon configuration or a standalone JACK server.

Volume UI should operate on the current default sink/device and react to device changes.

## Networking

Prefer Quickshell's native networking API when provided by the installed version.

If a required operation is not exposed, `nmcli` may be used as a focused fallback.

NetworkManager is the system network manager.

Do not replace NetworkManager.

## Bluetooth

Prefer Quickshell's Bluetooth/BlueZ integration.

Do not maintain Bluetooth state by repeatedly parsing `bluetoothctl` output unless required by a missing API.

## Media

Use MPRIS integration for media controls.

Do not create player-specific implementations unless absolutely required.

## Battery and power

Prefer UPower integration for battery state.

Avoid reading arbitrary `/sys` files directly when UPower/Quickshell exposes the information.

Power actions must be explicit and safe.

Do not execute shutdown/reboot/suspend immediately from accidental hover/click interactions. Require intentional interaction.

---

# Code quality

## Lua

- Prefer descriptive local variables.
- Avoid globals.
- Keep functions short.
- Do not hide simple Hyprland configuration behind unnecessary abstractions.
- Comment *why*, not obvious syntax.
- Keep config data close to the feature that consumes it.

## QML

- Components should have a clear responsibility.
- Avoid uncontrolled property bindings/cycles.
- Prefer readonly properties where appropriate.
- Avoid mutation of undeclared/global properties.
- Keep JavaScript helpers small.
- Extract reusable visual patterns only after duplication becomes real.
- Do not over-engineer early components.

## Formatting

Preserve the existing formatting conventions of the repository.

Do not reformat unrelated files.

Do not change working code solely to match personal style.

---

# Validation

After Hyprland configuration changes:

1. Save the modified Lua file.
2. Observe Hyprland's automatic reload.
3. If needed, explicitly reload with:

```bash
hyprctl reload
```

4. Check logs/errors before declaring the change complete.
5. Test the affected behavior directly.

After Quickshell changes:

1. Check QML/runtime warnings.
2. Resolve binding errors and invalid property writes.
3. Test reload behavior.
4. Verify UI on the current screen.
5. Consider multi-monitor implications even if only one monitor is connected.

Do not suppress warnings merely to make logs clean. Fix the underlying issue when practical.

---

# Package policy

Do not install packages automatically.

If a feature needs a new dependency:

1. identify the package;
2. explain why it is required;
3. state whether it comes from official Arch repositories or AUR;
4. propose the installation command;
5. wait for user approval.

The user currently uses `yay`, but official-repository packages remain preferred.

Use:

```bash
yay -S <package>
```

only after approval.

---

# System safety

The machine uses Btrfs and Snapper with manual snapshots.

Do not:

- create/delete Btrfs subvolumes;
- delete snapshots;
- modify `/etc/fstab`;
- change bootloader configuration;
- change partitions;
- modify Snapper cleanup policy;
- alter PAM;
- modify greetd system configuration;
- enable/disable system services;

without explicit user approval.

When proposing a risky system change, recommend creating a manual Snapper checkpoint first when appropriate.

Remember that the user's home directory is a separate Btrfs subvolume, so the root Snapper snapshots do **not** replace Git history/backups for dotfiles.

---

# Dotfiles and Git

Treat configuration files as code.

Before substantial edits:

```bash
git status
```

After changes:

- review the diff;
- avoid unrelated edits;
- keep commits focused.

Never overwrite local uncommitted changes without explicit approval.

Do not automatically commit or push unless asked.

Suggested logical scopes:

```text
hypr:
quickshell:
ghostty:
zsh:
starship:
greetd:
```

Example commit messages:

```text
hypr: add workspace keybindings
quickshell: add clock widget
quickshell: add PipeWire volume service
starship: refine prompt layout
```

---

# Working style for OpenCode

When asked to implement something:

1. Inspect the relevant existing files first.
2. Understand the current architecture before editing.
3. Check the installed/API version if version-sensitive behavior matters.
4. Prefer official Hyprland/Quickshell documentation over old examples, Reddit posts, or random dotfiles.
5. Explain briefly what will change.
6. Make the smallest coherent change.
7. Validate the result.
8. Report:
   - files changed;
   - behavior added/fixed;
   - validation performed;
   - any unresolved warning or manual step.

When debugging:

1. reproduce/inspect the actual error;
2. prefer logs and current runtime state over assumptions;
3. identify whether the problem is Hyprland, Quickshell, Qt/QML, systemd, Wayland, or an external service;
4. avoid shotgun configuration changes;
5. change one variable at a time.

---

# Things to avoid

Do not:

- copy large third-party Hyprland "rice" configurations into this project;
- introduce a desktop environment;
- convert the Lua Hyprland configuration back to legacy syntax;
- use deprecated Hyprland APIs when current Lua APIs exist;
- install Waybar as a shortcut instead of building the planned Quickshell panel;
- install another notification daemon when Quickshell notifications are being implemented;
- hard-code colors across QML components;
- hard-code `eDP-1` throughout Quickshell;
- poll shell commands continuously when a reactive API exists;
- start PipeWire/WirePlumber manually from Hyprland;
- make system-wide changes without user approval;
- optimize prematurely.

---

# Implementation roadmap

Use this only as a general direction. Do not implement future phases unless requested.

## Phase 1 — Hyprland foundation

- Monitor configuration
- Input
- Environment
- Appearance
- Basic window behavior
- Essential keybindings
- Workspace management
- Minimal autostart

## Phase 2 — Quickshell foundation

- Minimal `shell.qml`
- Theme tokens
- PanelWindow
- Clock
- Workspace indicator

## Phase 3 — Desktop status

- Battery
- Audio
- Brightness
- MPRIS
- System tray

## Phase 4 — Connectivity

- Network
- Bluetooth
- Related popups

## Phase 5 — Desktop interaction

- Notifications
- Launcher
- OSD
- Power/session menu

## Phase 6 — Session polish

- hypridle
- hyprlock
- optional Quickshell lock UI
- optional Quickshell greetd UI

---

# Definition of done

A change is complete when:

- it solves the requested behavior;
- it does not introduce unrelated dependencies;
- configuration remains modular and readable;
- there are no known new runtime errors caused by the change;
- the affected behavior has been tested;
- system-wide/manual follow-up steps are clearly stated;
- existing user customizations are preserved unless the task explicitly replaces them.
