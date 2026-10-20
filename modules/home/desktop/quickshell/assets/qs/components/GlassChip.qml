import QtQuick
import QtQuick.Layouts
import qs.theme

// Caelestia Material 3 Tactile Glass Chip
Rectangle {
    id: root

    property bool active: false
    property color fg: active ? Theme.chipActiveText : Theme.text
    property color bg: active ? Theme.accent : Qt.rgba(1, 1, 1, 0.05)
    property color hoverBg: active ? Qt.rgba(Theme.accent.r * 1.1, Theme.accent.g * 1.1, Theme.accent.b * 1.1, 1.0) : Qt.rgba(1, 1, 1, 0.12)
    property int squircleRadius: 13

    signal clicked
    signal rightClicked
    signal wheel(var wheel)

    color: chipMouse.containsMouse ? hoverBg : bg
    radius: squircleRadius
    border.color: active ? Qt.rgba(1, 1, 1, 0.30) : (chipMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.07))
    border.width: 1

    Behavior on color { ColorAnimation { duration: Motion.snappy } }
    Behavior on border.color { ColorAnimation { duration: Motion.snappy } }

    default property alias content: inner.children
    implicitWidth: inner.implicitWidth + 16
    implicitHeight: 26

    RowLayout {
        id: inner
        anchors.centerIn: parent
        spacing: 5
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
        onWheel: wheel => root.wheel(wheel)
    }
}
