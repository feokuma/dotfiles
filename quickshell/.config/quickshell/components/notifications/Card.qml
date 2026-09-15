import QtQuick
import Quickshell.Services.Notifications
import "../../theme"

// Visual card for a single notification. Lifecycle (tracking/expiry) is
// owned by the server; this component renders and auto-expires.
//
// Notifications expire in seconds per the Quickshell 0.3 API
// (spec clients send milliseconds; quickshell converts for us).
Rectangle {
    id: root

    required property var notification

    readonly property real durationSec: notification.expireTimeout > 0 ? notification.expireTimeout : Theme.notificationTimeoutSec
    // Critical notifications stay until dismissed by the user.
    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property real elapsedSec: expireTimer.elapsedSec

    width: Theme.notificationWidth
    height: content.implicitHeight + Theme.notificationPadding * 2
    radius: Theme.pillRadius
    // Border on the opaque container; translucency lives only on the
    // inner background so the 1px frame stays crisp, like the launcher.
    // The launcher itself is opaque; the pill opacity would also wash
    // out the border, hence no opacity here.
    color: Theme.pillBackground
    border.width: 1
    border.color: Theme.highlight

    Timer {
        id: expireTimer

        property real elapsedSec: 0

        interval: 100
        repeat: true
        // Paused while hovered so a notification stays readable; elapsedSec
        // is tracked manually, so resume continues where it left off.
        running: !root.critical && !root.hovered
        onTriggered: {
            elapsedSec += 0.1;
            if (elapsedSec >= root.durationSec)
                root.notification.expire();
        }
    }

    // Hovering keeps a notification readable until the pointer leaves;
    // clicking anywhere on the card dismisses it. Action buttons render
    // above this area (later in the QML tree), so their clicks win.
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.notification.dismiss()
    }

    // Timeout indicator: tracks remaining time; hidden for pinned/critical.
    Rectangle {
        id: timeoutBar

        visible: !root.critical
        anchors {
            left: parent.left
            leftMargin: Theme.notificationPadding
            bottom: parent.bottom
            bottomMargin: 6
        }
        width: parent.width - Theme.notificationPadding * 2
        height: 2
        radius: 1
        color: Theme.textMuted
        opacity: 0.6
        transform: Scale {
            origin.x: 0
            origin.y: 0
            xScale: Math.max(0, 1 - root.elapsedSec / root.durationSec)
        }
    }

    Column {
        id: content

        anchors {
            left: parent.left
            leftMargin: Theme.notificationPadding
            right: parent.right
            rightMargin: Theme.notificationPadding
            top: parent.top
            topMargin: Theme.notificationPadding
            bottomMargin: Theme.notificationPadding
        }
        spacing: Theme.notificationSpacing

        // App name lives on the header line.
        Text {
            id: appNameLabel

            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize - 2
            font.family: Theme.fontFamily
            font.bold: true
            color: root.critical ? Theme.warning : Theme.textMuted
            text: root.notification.appName
            textFormat: Text.PlainText
        }

        Text {
            width: parent.width
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize + 3
            font.family: Theme.fontFamily
            font.bold: Theme.fontBold
            color: Theme.text
            text: root.notification.summary
            textFormat: Text.PlainText
        }

        Text {
            width: parent.width
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
            visible: root.notification.body !== ""
            font.pixelSize: Theme.fontSize + 1
            font.family: Theme.fontFamily
            color: Theme.textMuted
            text: root.notification.body
            textFormat: Text.PlainText
        }

        Row {
            spacing: Theme.notificationSpacing
            visible: root.notification.actions.length > 0

            Repeater {
                model: root.notification.actions

                Rectangle {
                    required property var modelData

                    width: actionText.implicitWidth + 16
                    height: actionText.implicitHeight + 2 * 4
                    radius: Theme.pillRadius - 4
                    color: Theme.accent

                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        font.pixelSize: Theme.fontSize - 4
                        font.family: Theme.fontFamily
                        color: Theme.crust
                        text: parent.modelData.text
                        textFormat: Text.PlainText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.modelData.invoke()
                    }
                }
            }
        }
    }
}
