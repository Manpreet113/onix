import QtQuick
import Quickshell
import qs.theme

Text {
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 13
    font.bold: true
    color: Theme.text

    Behavior on color {
        ColorAnimation { duration: Motion.effects }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    text: Qt.formatDateTime(clock.date, "ddd MMM d  hh:mm")
}
