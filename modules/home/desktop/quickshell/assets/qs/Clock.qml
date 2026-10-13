import QtQuick
import Quickshell

Text {
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 14
    font.bold: true
    color: "#F2F2F2"

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    text: Qt.formatDateTime(clock.date, "ddd MMM d  hh:mm")
}
