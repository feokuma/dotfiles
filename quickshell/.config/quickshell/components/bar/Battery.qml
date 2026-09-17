import QtQuick
import Quickshell.Services.UPower
import "../../services"
import "../../theme"
import "../../widgets"

// Battery pill. Container visuals live in Pill; content here.
// Uses Quickshell.Services.UPower (native, reactive) — no Process/Timer
// polling. Clicking (shell.qml wires the popup) opens the power-profile
// selector. UPower.displayDevice.percentage is 0.0–1.0, so *100.
Pill {
    id: root

    visible: UPower.displayDevice.ready && UPower.displayDevice.isPresent && UPower.displayDevice.isLaptopBattery

    width: batteryText.width + Theme.pillPaddingH

    readonly property int level: Math.round(UPower.displayDevice.percentage * 100)
    readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging || UPower.displayDevice.state === UPowerDeviceState.PendingCharge

    // Glyph codepoints verified against the installed font (JetBrainsMono Nerd Font Mono).
    function batteryIcon(): string {
        const level = root.level;

        if (root.charging) {
            return "";
        }

        if (level >= 90)
            return "󰁹"; // md-battery (full)
        if (level >= 60)
            return "󰁿"; // md-battery-80
        if (level >= 40)
            return "󰁾"; // md-battery-60
        if (level >= 20)
            return "󰁽"; // md-battery-40
        if (level >= 15)
            return "󰁼"; // md-battery-20
        return "󰂎";     // md-battery-alert (low)
    }

    Text {
        id: batteryText

        anchors.centerIn: parent
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        color: batteryStatusColor()

        text: `${root.batteryIcon()} ${root.level}%`
    }

    function batteryStatusColor(): color {
        if (root.charging)
            return Theme.success;
        return root.level <= 15 ? Theme.warning : Theme.success;
    }

    // Popup (PowerProfilesPopup) attached by shell.qml; clicking toggles it.
    property var popup: null

    // Hover target for the battery hint; clicks open the power-profile popup.
    MouseArea {
        id: hoverArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.popup)
                root.popup.toggle();
        }
    }

    function hoverText(): string {
        const parts = [];
        const p = PowerProfileService.profile;
        if (p.length > 0)
            parts.push(p.charAt(0).toUpperCase() + p.slice(1));
        parts.push(root.charging ? "Charging" : "Discharging");
        return parts.join(" · ");
    }

    HoverHint {
        target: root
        text: hoverArea.containsMouse ? root.hoverText() : ""
        accent: root.batteryStatusColor()
    }
}
