// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixWLauncher: app-grid button (ports upstream bar launcher widget).
// Toggles the Onix launcher window (P3) via shared UI state.
import QtQuick

Item {
    id: root

    property int barId: 0

    implicitWidth: 40
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        color: hover.containsMouse ? OnixTheme.mPrimaryContainer : "transparent"
        radius: OnixTheme.radiusSmall
        Behavior on color {
            NumberAnimation {
                duration: OnixTheme.fadeFast
            }
        }

        Text {
            anchors.centerIn: parent
            text: "apps"
            color: hover.containsMouse ? OnixTheme.mOnPrimaryContainer : OnixTheme.mOnSurface
            font.family: OnixTheme.iconFont
            font.pixelSize: 22
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: OnixUi.toggleLauncher()
        }
    }
}
