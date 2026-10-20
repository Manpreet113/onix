import QtQuick
import QtQuick.Layouts
import qs.components
import qs.popups
import qs.services
import qs.theme

RowLayout {
    id: root
    spacing: 5

    Tray {}
    Audio {}
    Wifi {}
    Bt {}
    Batt {}

    // Notification toast / DND indicator
    GlassChip {
        id: notifChip
        active: Notif.hasToast
        fg: active ? Theme.textOnPrimary : Theme.text
        squircleRadius: 13
        implicitWidth: 28
        implicitHeight: 28

        Text {
            Layout.alignment: Qt.AlignCenter
            font.family: Theme.fontIcons
            font.pixelSize: 15
            color: notifChip.fg
            text: Sys.dnd ? "notifications_off" : (Notif.hasToast ? "notifications_active" : "notifications")
        }

        onClicked: {
            if (Notif.hasToast) {
                Notif.dismiss();
            } else {
                Sys.toggleDnd();
            }
        }
    }

    // Session / Power Trigger (Opens PowerPopup)
    GlassChip {
        id: powerChip
        active: PopupState.activePopup === "power"
        bg: active ? Theme.error : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12)
        hoverBg: active ? Theme.error : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.26)
        fg: active ? "#060606" : Theme.error
        squircleRadius: 13
        implicitWidth: 28
        implicitHeight: 28

        Text {
            Layout.alignment: Qt.AlignCenter
            font.family: Theme.fontIcons
            font.pixelSize: 15
            color: powerChip.fg
            text: "power_settings_new"
        }

        onClicked: PopupState.toggle("power")
    }
}
