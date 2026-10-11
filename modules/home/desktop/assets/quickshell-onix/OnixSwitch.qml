// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixSwitch: Material-3 switch (ports the m3 switch styles). Controlled
// component: set `checked` from settings, write back in `onToggled`.
// (Named `checked`, not `on`: bare `on:` reads as a signal-handler attach
// to the QML parser and silently breaks the binding.)
import QtQuick

Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 52
    implicitHeight: 32
    radius: OnixTheme.radiusFull
    color: root.checked ? OnixTheme.mPrimary : OnixTheme.mSurfaceContainerHighest
    border.color: root.checked ? "transparent" : OnixTheme.mOutline
    border.width: root.checked ? 0 : 2

    Behavior on color {
        NumberAnimation {
            duration: OnixTheme.fadeFast
        }
    }

    Rectangle {
        id: thumb
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 : 4
        width: root.checked ? 24 : 16
        height: width
        radius: width / 2
        color: root.checked ? OnixTheme.mOnPrimary : OnixTheme.mOutline
        Behavior on x {
            NumberAnimation {
                duration: OnixTheme.fadeFast
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: OnixTheme.fadeFast
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
