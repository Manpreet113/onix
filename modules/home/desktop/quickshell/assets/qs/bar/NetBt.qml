import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.components
import qs.popups
import qs.services
import qs.theme

GlassChip {
    id: root

    property bool btPowered: Bluetooth.defaultAdapter?.enabled ?? false
    property bool wifiOn: Sys.wifiEnabled

    active: PopupState.activePopup === "network"
    fg: root.active ? Theme.textOnPrimary : Theme.text
    squircleRadius: 13
    implicitWidth: 28
    implicitHeight: 28

    onClicked: PopupState.toggle("network")

    Text {
        Layout.alignment: Qt.AlignCenter
        font.family: Theme.fontIcons
        font.pixelSize: 15
        color: root.active ? Theme.textOnPrimary : (root.wifiOn ? Theme.text : Theme.dim)
        text: root.wifiOn ? "wifi" : (root.btPowered ? "bluetooth" : "wifi_off")
    }
}
