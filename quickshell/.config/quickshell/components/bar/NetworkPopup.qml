import Quickshell
import Quickshell.Networking
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "../../theme"
import "../../widgets"

// Network popup: scanned network list with inline PSK entry and
// connect/disconnect/forget. Opened by clicking the Network bar pill.
//
// Reads/writes go through the native Quickshell.Networking singleton
// (Networking.devices) using reactive property bindings — no nmcli parsing
// for anything the API covers. Verified against the 0.3.1 API docs:
//   WifiDevice.scannerEnabled / NetworkDevice.networks / WifiNetwork.security
//   WifiNetwork.signalStrength / Network.connect() / connectWithPsk(psk)
//   Network.disconnect() / forget() / connectionFailed(reason)
//
// NOTE: the 0.3.1 NetworkDevice API exposes no reactive rfkill/enable
// property, so there is deliberately no WiFi on/off toggle here;
// rfkill lives in the system layer.
//
// Container mirrors BluetoothPopup: a fullscreen invisible PanelWindow
// overlay with a rounded card anchored to the bar's right side, a
// click-outside catcher, and a fade+slide entrance. Per-monitor hosts stay
// deferred until a multi-monitor strategy exists (same as the other popups).
PanelWindow {
    id: root

    property bool isOpen: false

    // The wifi device, re-derived from the live device model (never cached:
    // NM recreates device objects after suspend/resume, so a stale reference
    // would leave the popup dead until reload).
    readonly property var wifiDevice: {
        const devices = Networking.devices.values;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi)
                return devices[i];
        }
        return null;
    }

    // The row whose PSK field is currently expanded (null = none). Lives at
    // popup root so opening one row collapses the others.
    property var expandedRow: null

    function open() {
        root.isOpen = true;
        root.expandedRow = null;
    }

    function close() {
        root.isOpen = false;
    }

    function toggle() {
        root.isOpen ? root.close() : root.open();
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
    WlrLayershell.namespace: "quickshell:network-popup"

    // Fullscreen click-outside catcher; the card sits on top of it.
    MouseArea {
        anchors.fill: parent
        onPressed: root.close()
    }

    // Network signal glyphs (MDI wifi-strength family), codepoints verified
    // against the installed font's cmap (JetBrainsMono Nerd Font). The
    // -lock variants fold the security lock into the signal glyph so each
    // row renders ONE icon instead of glyph + padlock.
    readonly property var signalGlyphs: ({
            s1: "󰤟"     // nf-md-wifi-strength-1-lock (lock variant)
            ,
            s2: "󰤧"     // nf-md-wifi-strength-2-lock
            ,
            s3: "󰤯"     // nf-md-wifi-strength-3-lock
            ,
            s4: "󰤲"     // nf-md-wifi-strength-4-lock
            ,
            s1o: "󰤞"    // nf-md-wifi-strength-1 (open)
            ,
            s2o: "󰤦"    // nf-md-wifi-strength-2
            ,
            s3o: "󰤮"    // nf-md-wifi-strength-3
            ,
            s4o: "󰤱"     // nf-md-wifi-strength-4
        })

    function signalGlyph(strength: real, locked: bool): string {
        const g = root.signalGlyphs;
        let base;
        if (strength >= 0.75)
            base = locked ? g.s4 : g.s4o;
        else if (strength >= 0.50)
            base = locked ? g.s3 : g.s3o;
        else if (strength >= 0.25)
            base = locked ? g.s2 : g.s2o;
        else
            base = locked ? g.s1 : g.s1o;
        return base;
    }

    // True when the security type requires a PSK (per 0.3.1 docs, PSKs are
    // only valid for WpaPsk / Wpa2Psk / Sae). Other secured types (WEP,
    // 802.1X) are not prompted for here — connect() may still work if NM
    // already holds their settings.
    function needsPsk(security): bool {
        return security === WifiSecurityType.WpaPsk || security === WifiSecurityType.Wpa2Psk || security === WifiSecurityType.Sae;
    }

    Rectangle {
        id: panel

        anchors {
            top: parent.top
            right: parent.right
            rightMargin: Theme.barMargin
        }
        width: Theme.popupWidth
        height: Math.min(contentColumn.implicitHeight + Theme.popupPadding * 2, root.height - margins.top - 10)
        radius: Theme.pillRadius
        color: Theme.crust
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

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: Theme.popupPadding
                bottomMargin: Theme.popupPadding
                leftMargin: Theme.popupPadding
                rightMargin: Theme.popupPadding
            }
            spacing: 6

            // Header row with the scan toggle on the right.
            Item {
                id: headerRow

                width: contentColumn.width - contentColumn.leftPadding - contentColumn.rightPadding
                height: Theme.popupRowHeight

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wi-Fi"
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    color: Theme.textMuted
                }

                // Scan (scannerEnabled) toggle: mirrors the bluetooth scan
                // pattern — a themed Button that drives a reactive backend
                // property. Active (filled) while scanning.
                TextButton {
                    anchors.verticalCenter: headerRow.verticalCenter
                    anchors.right: parent.right
                    text: root.wifiDevice && root.wifiDevice.scannerEnabled ? "Scanning…" : "Scan"
                    active: !!root.wifiDevice && root.wifiDevice.scannerEnabled
                    enabled: !!root.wifiDevice
                    onClicked: {
                        if (root.wifiDevice)
                            root.wifiDevice.scannerEnabled = !root.wifiDevice.scannerEnabled;
                    }
                }
            }

            // No wifi device (rfkilled, missing driver, ...).
            Text {
                visible: !root.wifiDevice
                text: "No Wi-Fi device found"
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                color: Theme.textMuted
                width: headerRow.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: 6
                bottomPadding: 6
            }

            // Scanned networks. The Repeater binds to the device's live
            // ObjectModel so rows come and go reactively as scans populate.
            Repeater {
                model: root.wifiDevice ? root.wifiDevice.networks : null

                delegate: NetworkRow {
                    visible: !!root.wifiDevice
                    network: modelData
                }
            }
        }
    }

    // Keyboard input for layershell surfaces (the PSK TextField needs it):
    // wlr-layer-shell defaults to no keyboard focus, so without this the
    // password field never receives keys. OnDemand = grab keys only when an
    // element inside the surface has focus.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // One network row: signal glyph (lock folded in), SSID, right-hand
    // status; click to connect/disconnect, expandable inline PSK field,
    // forget action for known networks. Expansion state lives at popup
    // root (root.expandedRow) so only one row expands at a time.
    component NetworkRow: Item {
        id: row

        property var network: null

        readonly property bool expanded: root.expandedRow === row

        // Error message for the current connect attempt (empty = none).
        property string errorText: ""

        width: contentColumn.width - contentColumn.leftPadding - contentColumn.rightPadding
        height: visible ? (Theme.popupRowHeight + (expanded ? pskField.height + 6 : 0)) : 0

        readonly property bool connected: network ? network.connected : false
        readonly property bool busy: network ? network.stateChanging : false

        // Security requires a PSK per the 0.3.1 rule (WpaPsk/Wpa2Psk/Sae).
        readonly property bool locked: network ? root.needsPsk(network.security) : false

        // A PSK network that NM has stored settings for connects without a
        // prompt (per connectWithPsk docs: "calling connect() first is
        // recommended to avoid having to show a prompt").
        readonly property bool needsPassword: locked && !network.known

        readonly property real strength: network ? network.signalStrength : 0.0

        onNetworkChanged: {
            if (root.expandedRow === row)
                root.expandedRow = null;
            row.errorText = "";
        }

        // Always-visible strip at the top of the row (SSID, signal, status).
        // Row content centers on this instead of the whole Item so the line
        // stays put when the PSK field grows the row's height below it.
        Item {
            id: rowHeader

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.popupRowHeight
        }

        Rectangle {
            id: hoverRect

            // Hover highlight only over the header strip: while expanded,
            // the PSK area below must not glow as if the row were hoverable.
            anchors.fill: rowHeader
            radius: Theme.pillRadius
            color: Theme.highlight
            opacity: hoverArea.containsMouse ? 0.12 : 0.0
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animFast
                }
            }
        }

        Text {
            id: iconSlot

            anchors.verticalCenter: rowHeader.verticalCenter
            anchors.left: parent.left
            width: 24
            text: root.signalGlyph(row.strength, row.locked)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 4
            font.bold: Theme.fontBold
            color: row.connected ? Theme.accent : Theme.text
        }

        Text {
            anchors.verticalCenter: rowHeader.verticalCenter
            anchors.left: iconSlot.right
            anchors.leftMargin: 10
            anchors.right: strengthText.left
            anchors.rightMargin: 8
            text: network ? network.name : ""
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: row.connected || row.needsPassword ? Theme.text : Theme.textMuted
        }

        // Numeric signal strength (signalStrength is 0.0..1.0), shown as a
        // percentage next to the signal glyph.
        Text {
            id: strengthText

            anchors.verticalCenter: rowHeader.verticalCenter
            anchors.right: statusText.left
            anchors.rightMargin: 8
            text: row.network ? Math.round(row.strength * 100) + "%" : ""
            font.pixelSize: Theme.fontSize - 2
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: Theme.textMuted
        }

        Text {
            id: statusText

            anchors.verticalCenter: rowHeader.verticalCenter
            anchors.right: row.expanded ? forgetButton.left : parent.right
            anchors.rightMargin: row.expanded ? 10 : 0
            text: {
                if (!row.network)
                    return "";
                if (row.network.state === ConnectionState.Connecting)
                    return "Connecting";
                if (row.network.state === ConnectionState.Disconnecting)
                    return "Disconnecting";
                if (row.connected)
                    return "Connected";
                return "";
            }
            font.pixelSize: Theme.fontSize - 1
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: row.connected ? Theme.success : Theme.textMuted
        }

        // Forget action, shown on hover for known (saved) networks. Uses the
        // 0.3.1 Network.forget() invokable; only meaningful while not
        // connected, since disconnect() is the row's primary click action.
        TextButton {
            id: forgetButton

            // Sits above hoverArea (declared later, covers the whole row):
            // without z its clicks land on the row handler instead (which
            // would connect to the network). hoverEnabled stays off so
            // hoverArea keeps driving containsMouse — the button hides
            // itself otherwise.
            z: 1

            readonly property bool shown: hoverArea.containsMouse && row.network && row.network.known && !row.connected

            anchors.verticalCenter: rowHeader.verticalCenter
            anchors.right: parent.right
            text: "Forget"
            visible: opacity > 0
            opacity: shown ? 1.0 : 0.0
            enabled: shown
            // Never accepts hover itself: hoverArea (row) keeps driving
            // containsMouse, which controls `shown`. Accepting hover here
            // would flip shown off under the cursor and oscillate.
            hoverEnabled: false
            font.pixelSize: Theme.fontSize - 2
            leftPadding: 6
            rightPadding: 6

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animFast
                }
            }

            onClicked: {
                if (row.network)
                    row.network.forget();
            }
        }

        MouseArea {
            id: hoverArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!row.network)
                    return;
                if (row.expanded) {
                    root.expandedRow = null;
                    return;
                }
                if (row.connected) {
                    row.network.disconnect();
                    return;
                }
                // Saved/open networks connect directly; PSK prompts first.
                if (row.needsPassword) {
                    row.errorText = "";
                    root.expandedRow = row;
                    return;
                }
                row.network.connect();
            }
        }

        // Inline PSK entry, shown below the row when expanded.
        Column {
            id: pskField

            visible: row.expanded

            // Focus when the field appears; forceActiveFocus because the
            // popup is a layershell surface (also re-focuses after a failed
            // attempt, handled by the Connections block below).
            onVisibleChanged: {
                if (visible)
                    pskInput.forceActiveFocus();
            }
            anchors {
                top: parent.top
                topMargin: Theme.popupRowHeight
                left: parent.left
                right: parent.right
            }
            spacing: 4

            Text {
                text: "Password"
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                color: Theme.textMuted
            }

            TextField {
                id: pskInput

                width: parent.width
                height: 30
                echoMode: TextInput.Password
                placeholderText: "Password"
                font.pixelSize: Theme.fontSize - 2
                font.family: Theme.fontFamily
                color: Theme.text
                // Border marks the field: muted normally, text-colored while
                // focused for clear affordance, warning on a failed attempt.
                background: Rectangle {
                    radius: 6
                    color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.9)
                    border.width: 1
                    border.color: row.errorText.length > 0 ? Theme.warning : pskInput.activeFocus ? Theme.text : Theme.textMuted
                }
                enabled: !row.busy

                onAccepted: row.tryConnect()
            }

            Text {
                visible: row.errorText.length > 0
                text: row.errorText
                font.pixelSize: Theme.fontSize - 2
                font.family: Theme.fontFamily
                font.bold: Theme.fontBold
                color: Theme.warning
                width: parent.width
            }

            Row {
                anchors.right: parent.right
                spacing: 6

                TextButton {
                    text: "Cancel"
                    onClicked: {
                        root.expandedRow = null;
                        row.errorText = "";
                    }
                }

                TextButton {
                    text: row.busy ? "Connecting…" : "Connect"
                    active: row.busy
                    enabled: !row.busy && pskInput.text.length > 0
                    onClicked: row.tryConnect()
                }
            }
        }

        function tryConnect() {
            if (!row.network || pskInput.text.length === 0)
                return;
            row.errorText = "";
            // Read the password first: the field is cleared and the prompt
            // collapsed immediately, while NM negotiates in the background.
            const psk = pskInput.text;
            root.expandedRow = null;
            pskInput.clear();
            row.network.connectWithPsk(psk);
        }

        // Wire the failure signal to the inline error. connectionFailed()
        // fires on the network object; keep the popup open and show the
        // message under the field.
        Connections {
            target: row.network

            function onConnectionFailed(reason) {
                if (reason === ConnectionFailReason.NoSecrets) {
                    row.errorText = "Wrong password";
                    root.expandedRow = row;
                    pskInput.selectAll();
                    pskInput.forceActiveFocus();
                } else {
                    row.errorText = "Failed: " + ConnectionFailReason.toString(reason);
                }
            }

            // Successful connection: collapse the PSK entry back into the
            // plain network list (failures keep it open for retry).
            function onStateChanged(state) {
                if (state === ConnectionState.Connected && root.expandedRow === row) {
                    root.expandedRow = null;
                    row.errorText = "";
                    pskInput.clear();
                }
            }
        }
    }
}
