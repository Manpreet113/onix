import QtQuick
import QtQuick.Layouts
import qs.components
import qs.popups
import qs.services
import qs.theme

// Dedicated Independent Bluetooth Glass Chip
GlassChip {
    id: root

    active: PopupState.activePopup === "bluetooth"
    fg: root.active ? Theme.textOnPrimary : Theme.text
    squircleRadius: 13
    implicitWidth: 28
    implicitHeight: 28

    onClicked: PopupState.toggle("bluetooth")

    Text {
        Layout.alignment: Qt.AlignCenter
        font.family: Theme.fontIcons
        font.pixelSize: 15
        color: root.active ? Theme.textOnPrimary : (Sys.btConnectedCount > 0 ? Theme.accent : (Sys.btEnabled ? Theme.text : Theme.dim))
        text: {
            if (!Sys.btEnabled) return "bluetooth_disabled";
            if (Sys.btConnectedCount > 0) return "bluetooth_connected";
            return "bluetooth";
        }
    }
}
