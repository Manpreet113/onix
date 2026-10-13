import QtQuick
import QtQuick.Layouts

// NOTE: plain row — Bar.qml already wraps this in an Island.
// (Nesting an Island here drew a double border.)
RowLayout {
    id: root
    spacing: 4

    Tray {}
    Audio {}
    NetBt {}
    Batt {}

    Pill {
        Text {
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            color: "#F2F2F2"
            text: "󰂚"
        }
    }
    Pill {
        Text {
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            color: "#F2F2F2"
            text: "󰒓"
        }
    }
    Pill {
        fg: "#B69690"
        hover: "#40B69690"
        Text {
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            color: "#B69690"
            text: "⏻"
        }
    }
}
