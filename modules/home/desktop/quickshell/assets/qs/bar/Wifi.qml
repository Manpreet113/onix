import QtQuick
import QtQuick.Layouts
import qs.components
import qs.popups
import qs.services
import qs.theme

// Dedicated Independent Wi-Fi Glass Chip
GlassChip {
    id: root

    active: PopupState.activePopup === "wifi"
    fg: root.active ? Theme.textOnPrimary : Theme.text
    squircleRadius: 13
    implicitWidth: 28
    implicitHeight: 28

    onClicked: PopupState.toggle("wifi")

    Text {
        Layout.alignment: Qt.AlignCenter
        font.family: Theme.fontIcons
        font.pixelSize: 15
        color: root.active ? Theme.textOnPrimary : (Sys.wifiConnected ? Theme.accent : (Sys.wifiEnabled ? Theme.text : Theme.dim))
        text: {
            if (!Sys.wifiEnabled) return "wifi_off";
            if (!Sys.wifiConnected) return "wifi";
            if (Sys.wifiSignal >= 75) return "signal_wifi_4_bar";
            if (Sys.wifiSignal >= 50) return "network_wifi_3_bar";
            if (Sys.wifiSignal >= 25) return "network_wifi_2_bar";
            return "network_wifi_1_bar";
        }
    }
}
