import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.popups
import qs.theme

GlassChip {
    id: root
    visible: UPower.displayDevice != null

    property real pctRaw: UPower.displayDevice?.percentage ?? 0
    property real pct: pctRaw > 1 ? pctRaw : pctRaw * 100
    property bool charging: {
        const s = UPower.displayDevice?.state;
        return s === UPowerDeviceState.Charging || s === UPowerDeviceState.FullyCharged;
    }

    readonly property string iconName: {
        if (charging) return "battery_charging_full";
        if (pct <= 15) return "battery_alert";
        if (pct <= 30) return "battery_2_bar";
        if (pct <= 50) return "battery_3_bar";
        if (pct <= 70) return "battery_5_bar";
        if (pct <= 90) return "battery_6_bar";
        return "battery_full";
    }

    active: PopupState.activePopup === "battery"
    fg: {
        if (root.active) return Theme.textOnPrimary;
        if (charging) return Theme.signalLed;
        if (pct <= 20) return Theme.error;
        return Theme.text;
    }
    squircleRadius: 13
    implicitWidth: 28
    implicitHeight: 28

    onClicked: PopupState.toggle("battery")

    Text {
        Layout.alignment: Qt.AlignCenter
        font.family: Theme.fontIcons
        font.pixelSize: 16
        color: root.fg
        text: root.iconName
    }
}
