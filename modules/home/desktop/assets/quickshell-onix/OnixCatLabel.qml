// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixCatLabel: icon + title settings section header (ports upstream
// CategoryLabel).
import QtQuick

// CategoryLabel: icon + title section header.
Item {
    id: catLabel
    property string icon: ""
    property string title: ""

    implicitWidth: row.implicitWidth
    implicitHeight: 28

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Text {
            visible: catLabel.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: catLabel.icon
            color: OnixTheme.mOnSurfaceVariant
            font.family: OnixTheme.iconFont
            font.pixelSize: 20
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: catLabel.title
            color: OnixTheme.mOnSurface
            font.pixelSize: OnixTheme.fontLarge
            font.bold: true
        }
    }
}
