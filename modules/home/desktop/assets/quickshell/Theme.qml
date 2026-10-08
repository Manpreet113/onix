pragma Singleton

import QtQuick
import Quickshell

// Onix shell design tokens. Every overlay component reads from here —
// change the feel of the whole shell in one place.
Singleton {
    // nord palette
    readonly property color bg: "#2e3440"
    readonly property color surface: "#3b4252"
    readonly property color border: "#4c566a"
    readonly property color text: "#eceff4"
    readonly property color subtext: "#d8dee9"
    readonly property color dim: "#6c7a96"
    readonly property color blue: "#81a1c1"
    readonly property color cyan: "#88c0d0"
    readonly property color red: "#bf616a"
    readonly property color green: "#a3be8c"
    readonly property color yellow: "#ebcb8b"
    readonly property color backdrop: "#000000"

    // shape
    readonly property int radiusSmall: 6
    readonly property int radiusMed: 8
    readonly property int radiusLarge: 14

    // type
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSmall: 12
    readonly property int fontMed: 13
    readonly property int fontLarge: 15
    readonly property int fontTitle: 22

    // motion (ms)
    readonly property int fadeFast: 130
    readonly property int fadeMed: 160
    readonly property int openSpring: 220
}
