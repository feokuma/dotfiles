pragma Singleton
import Quickshell
import QtQuick

// Central visual tokens for the bar.
// Values migrated from Clock.qml / Workspaces.qml / shell.qml;
// adjust here to change every pill at once.
QtObject {
    // Bar
    readonly property int barHeight: 42
    readonly property int barMargin: 10

    // Pill
    readonly property color pillBackground: "black"
    readonly property real pillOpacity: 0.7
    readonly property int pillRadius: 9
    // Fixed pill height shared by every bar pill (clock, workspaces).
    // 36 = measured text height at fontSize 15 (20px) + two paddings (2x8).
    // If fontSize grows a lot, raise pillHeight together so text never clips.
    readonly property int pillHeight: 38
    readonly property int pillPaddingH: 16
    readonly property int pillPaddingV: 8
    readonly property int itemSpacing: 10

    // Typography
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 15
    readonly property bool fontBold: true

    // Semantic colors (current values only, no new palette yet)
    readonly property color accent: "#cdd6f4"
    readonly property color text: "#cdd6f4"
    readonly property color textOnAccent: "black"
    readonly property color success: "#a6e3a1"
    readonly property color warning: "#f38ba8"
}
