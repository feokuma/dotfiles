import QtQuick
import Quickshell.Services.UPower
import "../../theme"
import "../../widgets"

// Battery pill. Container visuals live in Pill; content here.
// Uses Quickshell.Services.UPower (native, reactive) — no Process/Timer polling.
// UPower.displayDevice.percentage is 0.0–1.0 (energy/energyCapacity), so *100.
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

    // Hint color matches the icon for the current state (charge/low battery),
    // mirroring the WiFi hint's icon-colored border.
    function batteryStatusColor(): color {
        if (root.charging)
            return Theme.success;
        return root.level <= 15 ? Theme.warning : Theme.success;
    }

    // Hover target for the battery hint; hover-only, clicks stay untouched.
    MouseArea {
        id: hoverArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // Charge state shown below the pill while hovered.
    HoverHint {
        target: root
        text: hoverArea.containsMouse
            ? (root.charging ? "Charging" : "Discharging") : ""
        accent: root.batteryStatusColor()
    }
}
