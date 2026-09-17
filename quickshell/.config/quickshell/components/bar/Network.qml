import QtQuick
import Quickshell.Networking
import "../../theme"
import "../../widgets"

Pill {
    id: root

    width: label.implicitWidth + Theme.pillPaddingH

    property bool connected: false
    property real wifiSignal: 0.0
    property string wifiName: ""
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
        let name = "";

        for (let i = 0; i < devices.length; i++) {
            const d = devices[i];
            if (d.type !== DeviceType.Wifi)
                continue;

            watchDevice(d);

            const networks = d.networks.values;

            for (let j = 0; j < networks.length; j++) {
                const net = networks[j];

                watchNetwork(net, d.address);

                if (!net.connected)
                    continue;

                isWifiConnected = true;

                signal = net.signalStrength;
                name = net.name;

                break;
            }
        }

        connected = isWifiConnected;
        wifiSignal = signal;
        wifiName = name;
    }

    function networkLabel(): string {
        if (!connected)
            return "󰖪";
        return `  ${Math.round(wifiSignal * 100)}%`;
    }

    // Fallback resync: after suspend/resume, NM re-creates the network
    // objects while the connection is still re-establishing, so the final
    // `connected` transition can emit on an object this component started
    // watching only afterwards — leaving the stale "disconnected" state.
    // A cheap periodic re-scan fixes drift; normal updates stay event-driven.
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
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

    // Hover target for the WiFi hint; hover-only, so clicks stay click-through
    // on this pill (no click behavior defined here).
    MouseArea {
        id: hoverArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // Network name (SSID) shown below the pill while hovered.
    HoverHint {
        target: root
        text: hoverArea.containsMouse
            ? (root.connected ? root.wifiName : "Wi-Fi") : ""
        accent: Theme.yellow
    }
}
