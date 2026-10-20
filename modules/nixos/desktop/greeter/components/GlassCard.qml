import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property int squircleRadius: 20
    property int padH: 16
    property int padV: 16

    color: Theme.glassBg
    border.color: Theme.glassBorder
    border.width: 1
    radius: squircleRadius

    // Drop shadow
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: -4
        radius: root.radius + 2
        color: Theme.glassShadow
        opacity: 0.6
    }

    // Top edge specular glass highlight
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: root.radius / 2
        anchors.rightMargin: root.radius / 2
        height: 1
        color: Theme.glassSpecular
    }

    default property alias content: inner.children

    Item {
        id: inner
        anchors.fill: parent
        anchors.leftMargin: padH
        anchors.rightMargin: padH
        anchors.topMargin: padV
        anchors.bottomMargin: padV
    }
}
