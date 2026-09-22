import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls.Basic
import "../../theme"
import "../../widgets"

// Calendar popup: month grid centered under the bar's clock pill. Opened by
// clicking the clock.
//
// Container mirrors BluetoothPopup / PowerMenuPopup (PopupBase card with
// fade+slide entrance), but anchored to the bar's horizontal CENTER since
// the clock itself is centered. Pure QtQuick/QtQuick.Controls rendering —
// SystemClock supplies "today", no shell commands, no polling.
PopupBase {
    id: root

    // Fixed cell metrics drive the whole grid's geometry (a Column cannot
    // use implicitHeight from MonthGrid reliably, so keep it deterministic).
    readonly property int cellSize: 34

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    // First day of the displayed month. Rebuilt on every open so revisiting
    // the popup after month changes shows the current month; month
    // navigation always lands on day 1 (avoids the day-32 overflow problem
    // when stepping through a shorter month from a longer one).
    property date shownMonth: systemClock.date

    readonly property string monthTitle: {
        const locale = Qt.locale();
        return locale.standaloneMonthName(shownMonth.getMonth())
                + " " + shownMonth.getFullYear();
    }

    function prevMonth() {
        const d = shownMonth;
        shownMonth = new Date(d.getFullYear(), d.getMonth() - 1, 1);
    }

    function nextMonth() {
        const d = shownMonth;
        shownMonth = new Date(d.getFullYear(), d.getMonth() + 1, 1);
    }

    function showCurrentMonth() {
        shownMonth = new Date(systemClock.date.getFullYear(), systemClock.date.getMonth(), 1);
    }

    onPopupOpened: showCurrentMonth()

    visible: root.isOpen
    color: "transparent"
    margins.top: Theme.barHeight + Theme.popupBarGap

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:calendar-popup"

    // Fullscreen click-outside catcher; the card sits on top of it.
    MouseArea {
        anchors.fill: parent
        onPressed: root.close()
    }

    Rectangle {
        id: panel

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }
        width: Theme.popupWidth
        height: contentColumn.implicitHeight
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

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            topPadding: Theme.popupPadding
            bottomPadding: Theme.popupPadding
            leftPadding: Theme.popupPadding
            rightPadding: Theme.popupPadding
            spacing: 4

            // Header: prev-month arrow, "Month YYYY", next-month arrow.
            Item {
                id: headerRow

                width: contentColumn.width - contentColumn.leftPadding - contentColumn.rightPadding
                height: Theme.popupRowHeight

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    text: "Today"
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    color: todayArea.containsMouse ? Theme.accent : Theme.textMuted
                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animFast
                        }
                    }

                    MouseArea {
                        id: todayArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showCurrentMonth()
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.monthTitle
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    color: Theme.text
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    spacing: 10

                    TextButton {
                        text: "‹"
                        onClicked: root.prevMonth()
                    }

                    TextButton {
                        text: "›"
                        onClicked: root.nextMonth()
                    }
                }
            }

            // Weekday abbreviations, platform locale.
            DayOfWeekRow {
                id: weekHeader

                // Inner width, like the other rows (not the Column's full
                // anchor width, which would overflow the card padding).
                width: headerRow.width

                delegate: Text {
                    text: model.shortName
                    font.pixelSize: Theme.fontSize - 2
                    font.family: Theme.fontFamily
                    font.bold: Theme.fontBold
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            MonthGrid {
                id: monthGrid

                width: headerRow.width
                height: 6 * root.cellSize
                month: root.shownMonth.getMonth()
                year: root.shownMonth.getFullYear()
                locale: Qt.locale()

                delegate: Rectangle {
                    id: dayCell

                    required property date date
                    required property int day
                    required property bool today

                    readonly property bool inShownMonth: date.getMonth() === root.shownMonth.getMonth()
                    readonly property bool isWeekend: date.getDay() === 0 || date.getDay() === 6
                    readonly property bool hovered: hoverArea.containsMouse && hoverArea.enabled

                    width: root.cellSize
                    height: root.cellSize
                    radius: Theme.pillRadius
                    color: today ? Theme.accent : hovered ? Theme.highlight : "transparent"
                    opacity: today ? 0.9 : hovered ? 0.16 : 1.0

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animFast
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.day
                        font.pixelSize: Theme.fontSize - 2
                        font.family: Theme.fontFamily
                        font.bold: Theme.fontBold
                        color: dayCell.today ? Theme.crust
                            : !dayCell.inShownMonth ? Theme.textMuted
                            : dayCell.isWeekend ? Theme.peach : Theme.text
                        opacity: dayCell.inShownMonth ? 1.0 : 0.4
                    }

                    MouseArea {
                        id: hoverArea

                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.isOpen && !dayCell.today
                    }
                }
            }
        }
    }
}
