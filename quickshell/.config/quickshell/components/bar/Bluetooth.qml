import QtQuick
import Quickshell.Bluetooth
import "../../theme"
import "../../widgets"

Pill {
    id: root

    visible: Bluetooth.defaultAdapter !== null

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter ? adapter.enabled : false
    property int deviceCount: 0
    property var watched: ({})

    width: btText.implicitWidth + Theme.pillPaddingH

    function refresh() {
        let count = 0;
        if (!adapter) {
            root.deviceCount = 0;
            return;
        }
        const vals = adapter.devices.values;
        for (let i = 0; i < vals.length; i++) {
            const d = vals[i];
            if (d.connected) count++;
            if (!root.watched[d.address]) {
                d.connectedChanged.connect(root.refresh);
                root.watched[d.address] = true;
            }
        }
        root.deviceCount = count;
    }

    onAdapterChanged: {
        root.watched = {};
        if (adapter)
            adapter.devices.valuesChanged.connect(root.refresh);
        root.refresh();
    }

    Component.onCompleted: {
        root.refresh();
        if (adapter)
            adapter.devices.valuesChanged.connect(root.refresh);
    }

    function btIcon(): string {
        if (!root.enabled) return "󰂲";
        if (root.deviceCount > 0) return "󰂰";
        return "󰂯";
    }

    function btColor(): color {
        if (!root.enabled) return Theme.textMuted;
        if (root.deviceCount > 0) return Theme.success;
        return Theme.accent;
    }

    Text {
        id: btText
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        color: root.btColor()
        text: root.deviceCount > 0
            ? `${root.btIcon()} ${root.deviceCount}`
            : root.btIcon()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (root.adapter)
                root.adapter.enabled = !root.enabled;
        }
    }
}
