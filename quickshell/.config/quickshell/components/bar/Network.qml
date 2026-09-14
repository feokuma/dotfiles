import QtQuick
import Quickshell.Networking
import "../../theme"
import "../../widgets"

Pill {
    id: root

    width: label.implicitWidth + Theme.pillPaddingH

    property bool connected: false
    property real wifiSignal: 0.0
    property var watched: ({})

    function watchDevice(d) {
        const key = d.address;

        const dKey = key + "_dev";
        if (!watched[dKey]) {
            d.connectedChanged.connect(root.refresh);
            watched[dKey] = true;
        }

        const nKey = key + "_nets";
        if (!watched[nKey]) {
            d.networks.valuesChanged.connect(root.refresh);
            watched[nKey] = true;
        }
    }

    function watchNetwork(net, key) {
        const sKey = key + "_sig_" + net.name;
        if (!watched[sKey]) {
            net.signalStrengthChanged.connect(root.refresh);
            net.connectedChanged.connect(root.refresh);
            watched[sKey] = true;
        }
    }

    function refresh() {
        const devices = Networking.devices.values;
        let isWifiConnected = false;
        let signal = 0.0;

        for (let i = 0; i < devices.length; i++) {
            const d = devices[i];
            if (d.type !== DeviceType.Wifi)
                continue;

            watchDevice(d);

            if (!d.connected)
                continue;

            isWifiConnected = true;
            const networks = d.networks.values;
            for (let j = 0; j < networks.length; j++) {
                const net = networks[j];
                if (!net.connected)
                    continue;
                watchNetwork(net, d.address);
                signal = net.signalStrength;
            }
        }

        connected = isWifiConnected;
        wifiSignal = signal;
    }

    function networkLabel(): string {
        if (!connected)
            return "󰖪";
        return `  ${Math.round(wifiSignal * 100)}%`;
    }

    Component.onCompleted: {
        refresh();
        Networking.devices.valuesChanged.connect(refresh);
    }

    Text {
        id: label
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        font.bold: Theme.fontBold
        color: Theme.yellow
        text: root.networkLabel()
    }
}
