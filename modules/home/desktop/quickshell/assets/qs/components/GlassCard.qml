import QtQuick
import QtQuick.Layouts
import qs.theme

// Liquid Organic Glass Card primitive: Continuous squircle, frosted glass fill,
// specular top highlight, and soft ambient drop shadow.
Rectangle {
    id: root

    property int squircleRadius: 16
    property int padH: 12
    property int padV: 6
    property int gap: 8

    color: Theme.glassBg
    border.color: Theme.glassBorder
    border.width: 1
    radius: squircleRadius

    implicitWidth: inner.implicitWidth + padH * 2
    implicitHeight: inner.implicitHeight + padV * 2

    Behavior on color { ColorAnimation { duration: Motion.effects } }
    Behavior on border.color { ColorAnimation { duration: Motion.effects } }

    // Ambient drop shadow for spatial elevation above desktop windows
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        anchors.bottomMargin: -2
        radius: root.radius + 1
        color: Theme.glassShadow
        opacity: 0.6
    }

    // Top edge specular glass highlight (simulates refractive glass rim)
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: root.radius / 2
        anchors.rightMargin: root.radius / 2
        height: 1
        radius: 1
        color: Theme.glassSpecular
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
