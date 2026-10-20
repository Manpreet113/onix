import QtQuick
import QtQuick.Layouts
import qs.theme

// Floating pill island: translucent card, hairline border, fully round.
// Sized by content via implicit bindings (no anchors.fill circularity).
Rectangle {
    id: root
    color: Theme.islandBg
    border.color: Theme.border
    border.width: 1
    radius: 999

    implicitWidth: inner.implicitWidth + padH * 2
    implicitHeight: inner.implicitHeight + padV * 2

    property int padH: 8
    property int padV: 3
    property int gap: 6

    Behavior on color {
        ColorAnimation {
            duration: Motion.effects
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: Motion.effects
        }
    }

    default property alias content: inner.children

    RowLayout {
        id: inner
        anchors.fill: parent
        anchors.leftMargin: padH
        anchors.rightMargin: padH
        anchors.topMargin: padV
        anchors.bottomMargin: padV
        spacing: gap
    }
}
