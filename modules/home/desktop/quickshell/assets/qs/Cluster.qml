import QtQuick
import QtQuick.Layouts

Island {
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
