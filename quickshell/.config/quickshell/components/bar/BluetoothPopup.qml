import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "../../theme"

// Bluetooth popup: adapter power toggle, scan (discovery) toggle, paired
// device list and discovered devices while scanning. Opened by clicking the
// Bluetooth bar pill.
//
// Reads/writes go through the native Quickshell.Bluetooth singleton
// (Bluetooth.defaultAdapter) using reactive property bindings — no
// bluetoothctl parsing or polling. Adapter state is compared against the
// BluetoothAdapterState / BluetoothDeviceState enum singletons.
//
// Container mirrors AudioPopup: a fullscreen invisible PanelWindow overlay
// with a rounded card anchored to the bar's right side, a click-outside
// catcher, and a fade+slide entrance. Per-monitor hosts stay deferred until
// a multi-monitor strategy exists (same as the other popups).
PanelWindow {
    id: root

    property bool isOpen: false
    readonly property var adapter: Bluetooth.defaultAdapter

    function open() {
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
    }

    function toggle() {
        root.isOpen ? root.close() : root.open();
    }

    // Launch ghostty with bluetoothctl for pairing. setsid detaches ghostty
    // into its own session so a shell reload/restart never kills the pair
    // terminal. Process stays "running" briefly until setsid forks+exits.
    Process {
        id: ghosttyProc
        command: ["setsid", "ghostty", "-e", "bluetoothctl"]
        running: false
    }

    visible: root.isOpen
    color: "transparent"
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
    margins.top: Theme.barHeight + Theme.popupBarGap

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:bluetooth-popup"

    // Fullscreen click-outside catcher; the card sits on top of it.
    MouseArea {
        anchors.fill: parent
        onPressed: root.close()
    }

    // Reactive sync fallback. Quickshell 0.3.1 declares notify signals for
    // BluetoothDevice (connectedChanged, stateChanged, …) but never emits them
    // at runtime, so QML bindings freeze on the value seen at delegate
    // creation — the popup believed a disconnected headset was still
    // connected. Until signals work (or quickshell is updated), nudge all
    // device-state bindings once per second while the popup is open. The
    // timer only runs while isOpen, so closed state costs nothing.
    property int deviceStateTick: 0
    Timer {
        interval: 1000
        running: root.isOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: root.deviceStateTick++
    }

    // "Any paired" recomputed on demand: touching .values creates a
    // dependency on the model's valuesChanged signal (device add/remove).
    readonly property bool hasAnyPaired: {
        if (!adapter)
            return false;
        const vals = adapter.devices.values;
        for (let i = 0; i < vals.length; i++) {
            if (vals[i].paired)
                return true;
        }
        return false;
    }

    // Referenced by device-state bindings below so the sync ticker forces
    // their re-evaluation (see note on deviceStateTick).
    readonly property bool stateBindingTrigger: deviceStateTick >= 0

    // --- Centralized icon mapping -------------------------------------------------
    // BlueZ exposes each device's type as a freedesktop icon name via
    // `device.icon` (e.g. "audio-headphones", "input-keyboard", "phone"). This
    // session has no icon theme wired into Qt (bare Hyprland: no
    // QT_QPA_PLATFORMTHEME and no ~/.icons/default), so Quickshell.iconPath
    // cannot resolve them and every row falls through to a generic glyph —
    // the original "all icons look the same" bug.
    //
    // We therefore render a Nerd Font glyph per device type. All Unicode icon
    // literals live in this ONE map (AGENTS.md: don't scatter glyph literals).
    // Codepoints were verified against the installed font's `post` glyph-name
    // table (md-<name>), not guessed — e.g. md-bluetooth U+F00AF matches the
    // glyph already used in Bluetooth.qml.
    readonly property var bluetoothGlyphs: ({
        // Audio / headphones / speakers
        "audio-headphones": "󰋋",      // nf-md-headphones
        "audio-car": "󰋋",             // car head-unit, treat as headphones
        "headset": "󰋎",               // nf-md-headset
        "audio-headset": "󰋎",
        "audio-earbud": "󱡏",          // nf-md-earbuds
        "earbud": "󱡏",
        "audio-card": "󰓃",            // nf-md-speaker
        "speaker": "󰓃",
        "audio-input-microphone": "󰍬", // nf-md-microphone
        "microphone": "󰍬",
        // Input devices
        "input-keyboard": "󰌌",        // nf-md-keyboard
        "keyboard": "󰌌",
        "input-mouse": "󰍽",           // nf-md-mouse
        "mouse": "󰍽",
        "input-gaming": "󰊖",          // nf-md-gamepad
        "joystick": "󰊖",
        "gamepad": "󰊖",
        "input-tablet": "󰓶",          // nf-md-tablet
        // Phones / wearables / misc
        "phone": "󰏲",                 // nf-md-phone
        "smartphone": "󰏲",
        "tablet": "󰓶",
        "watch": "󰖉",                 // nf-md-watch
        "camera": "󰄀",                // nf-md-camera
        "camera-photo": "󰄀",
        "computer": "󰍹",              // nf-md-monitor
        "laptop": "󰍹",
        "printer": "󰐪",               // nf-md-printer
        "modem": "󰑩",                 // md-modem missing from font; router_wireless
        "network-wireless": "󰖩",       // nf-md-wifi
        "remote": "󰑔"                  // nf-md-remote
    })
    // Fallback glyph: plain bluetooth symbol, same codepoint as the bar pill.
    readonly property string bluetoothGlyphFallback: "󰂯" // nf-md-bluetooth

    // Resolve a BlueZ icon name to a glyph, tolerating the aliases BlueZ emits
    // for the same class (longest-match wins so "audio-headset" beats "headset").
    function deviceGlyph(iconName: string): string {
        if (!iconName)
            return root.bluetoothGlyphFallback;
        const key = iconName.toLowerCase();
        if (root.bluetoothGlyphs[key] !== undefined)
            return root.bluetoothGlyphs[key];
        const keys = Object.keys(root.bluetoothGlyphs);
        for (let i = 0; i < keys.length; i++) {
            if (key === keys[i])
                return root.bluetoothGlyphs[keys[i]];
        }
        return root.bluetoothGlyphFallback;
    }

    // Battery level glyphs (MDI battery family), codepoints verified against
    // the installed font; consistent with the levels used in Battery.qml.
    function batteryGlyph(pct: int): string {
        if (pct >= 90) return "󰁹"; // nf-md-battery
        if (pct >= 60) return "󰁿"; // md-battery-80
        if (pct >= 40) return "󰁾"; // nf-md-battery_60
        if (pct >= 20) return "󰁽"; // nf-md-battery_40
        if (pct >= 15) return "󰁼"; // nf-md-battery_20
        return "󰂎"; // nf-md-battery_alert (low)
    }

    Rectangle {
        id: panel

        anchors {
            top: parent.top
            right: parent.right
            rightMargin: Theme.barMargin
        }
        width: Theme.popupWidth
        height: contentColumn.implicitHeight + contentColumn.anchors.margins * 2
        radius: Theme.pillRadius
        color: Theme.pillBackground
        border.width: 1
        border.color: Theme.highlight
        clip: true

        opacity: root.isOpen ? 1 : 0

        readonly property int appearDuration: Theme.animFast

        transform: Translate {
            y: root.isOpen ? 0 : -14

            Behavior on y {
                NumberAnimation {
                    duration: panel.appearDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: panel.appearDuration
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: contentColumn

            anchors.fill: parent
            anchors.margins: 2
            topPadding: Theme.popupPadding
            bottomPadding: Theme.popupPadding
            leftPadding: Theme.popupPadding
            rightPadding: Theme.popupPadding
            spacing: 6

            // Header row with the adapter power toggle on the right.
            Item {
                id: headerRow

                width: contentColumn.width - contentColumn.leftPadding - contentColumn.rightPadding
                height: Theme.popupRowHeight

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bluetooth"
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    color: Theme.textMuted
                }

                // Adapter power: writing `enabled` turns the radio on/off;
                // the binding re-reads it via enabledChanged. While the
                // adapter settles (Enabling/Disabling) show a muted state.
                TogglePill {
                    id: powerToggle

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    label: {
                        if (!root.adapter)
                            return "\u2014";
                        if (root.adapter.state === BluetoothAdapterState.Enabling)
                            return "Turning on";
                        if (root.adapter.state === BluetoothAdapterState.Disabling)
                            return "Turning off";
                        return root.adapter.enabled ? "On" : "Off";
                    }
                    active: root.adapter ? root.adapter.enabled : false
                    busy: root.adapter
                          ? (root.adapter.state === BluetoothAdapterState.Enabling
                             || root.adapter.state === BluetoothAdapterState.Disabling)
                          : false
                    onActivated: {
                        if (root.adapter)
                            root.adapter.enabled = !root.adapter.enabled;
                    }
                }
            }

            // Everything below only makes sense with an adapter present and
            // powered on; show a hint otherwise.
            Text {
                visible: !root.adapter || !root.adapter.enabled
                text: root.adapter && root.adapter.state === BluetoothAdapterState.Blocked
                      ? "Bluetooth is blocked"
                      : "Turn Bluetooth on to see devices"
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                color: Theme.textMuted
                width: headerRow.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: 6
                bottomPadding: 6
            }

            // Pairing helper: pairing requires an agent interaction flow that
            // the shell does not implement, so hand off to bluetoothctl in
            // ghostty. Dispatched through Hyprland so the terminal's lifetime
            // is owned by the compositor, not this popup object.
            Item {
                id: pairRow

                visible: root.adapter && root.adapter.enabled
                width: headerRow.width
                height: visible ? Theme.popupRowHeight : 0

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Pair a device"
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    color: Theme.text
                }

                TogglePill {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    label: "Open bluetoothctl"
                    onActivated: ghosttyProc.running = true;
                }
            }

            // Section header for paired/bonded devices.
            SectionLabel {
                visible: root.adapter && root.adapter.enabled
                text: "Paired"
            }

            // Paired devices. Repeater is bound to the adapter's live model
            // so delegates are re-created reactively when devices come and
            // go. Column collapses invisible delegates, letting one Repeater
            // serve the "paired" subset.
            Repeater {
                model: root.adapter ? root.adapter.devices : null

                delegate: DeviceRow {
                    visible: root.adapter && root.adapter.enabled && modelData.paired
                    device: modelData
                }
            }

            Text {
                visible: root.adapter && root.adapter.enabled && !root.hasAnyPaired
                text: "No paired devices — use “Open bluetoothctl” above to pair"
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                color: Theme.textMuted
            }
        }
    }

    // Compact pill button used for the two adapter toggles (power / scan).
    // Local to this popup; a generic button only earns a widgets/ file once a
    // second consumer appears.
    component TogglePill: Rectangle {
        id: pill

        property string label
        property bool active: false
        property bool busy: false
        signal activated

        readonly property int hPad: 12

        implicitHeight: 26
        width: pillText.implicitWidth + hPad * 2
        radius: height / 2
        color: Theme.crust
        border.width: 1
        border.color: active ? Theme.accent : Theme.textMuted
        opacity: enabled ? 1.0 : 0.5

        Behavior on border.color {
            NumberAnimation {
                duration: Theme.animFast
            }
        }

        Text {
            id: pillText

            anchors.centerIn: parent
            text: pill.label
            font.pixelSize: Theme.fontSize - 1
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: pill.active ? Theme.accent : Theme.text
        }

        MouseArea {
            anchors.fill: parent
            enabled: pill.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.activated()
        }
    }

    // Muted section header ("Paired" / "Available").
    component SectionLabel: Text {
        font.pixelSize: Theme.fontSize + Theme.popupSectionFontDelta
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        color: Theme.textMuted
        topPadding: 4
    }

    // One device row: icon + name (fallback address) + battery/status;
    // clicking toggles connect/disconnect. All state binds straight to the
    // device object so Qt's NOTIFY signals keep it reactive.
    component DeviceRow: Item {
        id: row

        property var device: null

        width: contentColumn.width - contentColumn.leftPadding - contentColumn.rightPadding
        height: visible ? Theme.popupRowHeight : 0

        // Row is interactive only while a device is bound and the connection
        // is not mid-transition.
        readonly property bool busy: root.stateBindingTrigger && device
                                 && (device.state === BluetoothDeviceState.Connecting
                                     || device.state === BluetoothDeviceState.Disconnecting
                                     || device.pairing)

        // stateBindingTrigger keeps these bindings live despite missing
        // notify signals from the bluetooth service (see root.deviceStateTick).
        readonly property bool connected: root.stateBindingTrigger
                                          && (device ? device.connected : false)

        // Display name: prefer the friendly deviceName; fall back to MAC so
        // unnamed peripherals are still selectable.
        readonly property string displayName: {
            if (!device)
                return "";
            const name = device.deviceName;
            return (name && name.length > 0) ? name : device.address;
        }

        // Battery glyphs live at popup root (batteryGlyph) — shared by all rows.

        Rectangle {
            id: hoverRect

            anchors.fill: parent
            radius: Theme.pillRadius
            color: Theme.highlight
            opacity: hoverArea.containsMouse ? 0.12 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animFast
                }
            }
        }

        // Icon column. NOTE: Quickshell.iconPath() returns a non-empty provider
        // URL (image://icon/<name>) even when the icon is missing from the
        // installed theme, so an empty-path check never fires and IconImage
        // renders nothing useful for missing icons. There is no usable Qt icon
        // theme in this bare Hyprland session, so we render a per-device Nerd
        // Font glyph (resolved from the bluez icon name) directly instead.
        Text {
            id: iconSlot

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            width: 24
            text: root.deviceGlyph(device && device.icon ? device.icon : "")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 4
            font.bold: Theme.fontBold
            color: row.connected ? Theme.accent : Theme.text
        }

        // Right-hand status: battery + Connected/Connecting/… text.
        Text {
            id: statusText

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            text: {
                if (!row.device)
                    return "";
                const parts = [];
                if (row.device.batteryAvailable)
                    parts.push(`${batteryGlyph(row.device.battery * 100)} ${Math.round(row.device.battery * 100)}%`);
                if (row.device.state === BluetoothDeviceState.Connecting)
                    parts.push("Connecting");
                else if (row.device.state === BluetoothDeviceState.Disconnecting)
                    parts.push("Disconnecting");
                else if (row.device.pairing)
                    parts.push("Pairing");
                else if (row.connected)
                    parts.push("Connected");
                return parts.join("  ");
            }
            font.pixelSize: Theme.fontSize - 1
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: row.connected ? Theme.success : Theme.textMuted
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: iconSlot.right
            anchors.leftMargin: 10
            anchors.right: statusText.left
            anchors.rightMargin: 8
            text: row.displayName
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: row.connected ? Theme.text : Theme.textMuted
        }

        MouseArea {
            id: hoverArea

            anchors.fill: parent
            enabled: row.device && !row.busy
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (!row.device)
                    return;
                if (!row.device.paired) {
                    // Not yet paired (discovered while scanning): bond first.
                    // BlueZ refuses connect() on an unbonded device.
                    row.device.pair();
                } else if (row.connected)
                    row.device.disconnect();
                else
                    row.device.connect();
            }
        }
    }
}
