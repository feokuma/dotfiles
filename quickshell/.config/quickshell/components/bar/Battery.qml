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
    readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging
        || UPower.displayDevice.state === UPowerDeviceState.PendingCharge

    function batteryIcon(): string {
        const level = root.level;

        if (root.charging) {
            if (level >= 95)
                return "󰂆";
            if (level >= 85)
                return "󰂏";
            if (level >= 75)
                return "󰂎";
            if (level >= 65)
                return "󰂍";
            if (level >= 55)
                return "󰂌";
            if (level >= 45)
                return "󰂋";
            if (level >= 35)
                return "󰂊";
            if (level >= 25)
                return "󰂉";
            if (level >= 15)
                return "󰂈";
            if (level >= 5)
                return "󰂇";
            return "󰂄";
        }

        if (level >= 95)
            return "󰁹";
        if (level >= 85)
            return "󰂂";
        if (level >= 75)
            return "󰂁";
        if (level >= 65)
            return "󰂀";
        if (level >= 55)
            return "󰁿";
        if (level >= 45)
            return "󰁾";
        if (level >= 35)
            return "󰁽";
        if (level >= 25)
            return "󰁼";
        if (level >= 15)
            return "󰁻";
        if (level >= 5)
            return "󰁺";
        return "󰂃";
    }

    Text {
        id: batteryText

        anchors.centerIn: parent
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        color: root.level <= 20 ? Theme.warning : Theme.success

        text: `${root.batteryIcon()} ${root.level}%`
    }
}
