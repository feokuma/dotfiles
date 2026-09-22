pragma Singleton
import QtQuick
import "./colors"

// Central visual tokens for the bar.
// Values migrated from Clock.qml / Workspaces.qml / shell.qml;
// adjust here to change every pill at once.
QtObject {
    // Bar
    readonly property int barHeight: 42
    readonly property int barMargin: 10

    // Pill
    readonly property color pillBackground: crust
    readonly property real pillOpacity: 0.7
    readonly property int pillRadius: 9
    // Fixed pill height shared by every bar pill (clock, workspaces).
    // 36 = measured text height at fontSize 15 (20px) + two paddings (2x8).
    // If fontSize grows a lot, raise pillHeight together so text never clips.
    readonly property int pillHeight: 38
    readonly property int pillPaddingH: 26
    readonly property int pillPaddingV: 8
    readonly property int itemSpacing: 5

    // Typography
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 15
    readonly property bool fontBold: true

    // Palette flavor: swap this component to FrappeColors / LatteColors /
    // MacchiatoColors (all defined in ./colors) to retheme the whole shell.
    readonly property QtObject palette: MacchiatoColors {}

    // Semantic colors
    readonly property color text: palette.text
    readonly property color highlight: palette.text
    readonly property color accent: palette.blue
    readonly property color accentSecondary: palette.mauve
    readonly property color success: palette.green
    readonly property color warning: palette.red
    readonly property color textMuted: palette.overlay1
    readonly property color peach: palette.peach
    readonly property color yellow: palette.yellow
    readonly property color crust: palette.crust

    // System tray
    readonly property int trayIconSize: 20

    // Notifications
    readonly property int notificationWidth: 400
    readonly property int notificationTopGap: 4 // gap below the bar's bottom edge
    readonly property int notificationPadding: 14
    readonly property int notificationSpacing: 4
    readonly property int notificationStackSpacing: 10
    readonly property int notificationTimeoutSec: 5  // fallback for expireTimeout <= 0

    // About window ("About this system", opened from the power menu).
    // Padding keeps the info rows off the card edges. The full card width
    // is dynamic: proportional logo art + gap + this fixed info column
    // (460px fits the longest info line, "Display (...)" ~432px).
    readonly property int aboutInfoWidth: 460
    readonly property int aboutPadding: 26
    readonly property int aboutRowSpacing: 8

    // Animation durations
    readonly property int animFast: 150
    // Softer, more deliberate transitions (switches, state changes).
    readonly property int animSlow: 250

    // Audio popup
    readonly property int popupTrackHeight: 10

    // Popups (shared geometry for the bar-anchored overlay cards: audio,
    // bluetooth, ...). Centralized so the card look stays identical and a
    // single change rethemes every popup.
    readonly property int popupWidth: 350
    readonly property int popupPadding: 14
    // Vertical gap between the bar's bottom edge and the popup card.
    readonly property int popupBarGap: 6
    // Row height for the device/toggle rows inside popups.
    readonly property int popupRowHeight: 40
    // Section header (muted label) size offset relative to Theme.fontSize.
    readonly property int popupSectionFontDelta: 0
}
