// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// M3Slider: Material-3 slider in a tonal container (ports upstream Slider).
// Track is secondary-container, fill + square-ish handle are primary, value
// bubble appears while dragging. Emits `moved(value)` on user drags; set
// `value` externally to drive it.
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property real from: 0
    property real to: 100
    property real value: 50
    property real step: 1
    property bool vertical: false
    property string icon: ""

    signal moved(real value)

    implicitWidth: root.vertical ? 64 : 220
    implicitHeight: root.vertical ? 220 : 64

    Rectangle {
        anchors.fill: parent
        color: OnixTheme.mSurfaceContainer
        radius: 24

        Row {
            id: row
            anchors.fill: parent
            anchors.margins: 10
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 10
            layoutDirection: Qt.LeftToRight

            Text {
                id: iconText
                visible: root.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: root.icon
                color: OnixTheme.mOnSurface
                font.family: OnixTheme.iconFont
                font.pixelSize: 24
            }

            Slider {
                id: slider
                width: root.vertical ? 24 : row.width - (iconText.visible ? iconText.width + 10 : 0)
                height: root.vertical ? row.height : 24
                anchors.verticalCenter: parent.verticalCenter
                orientation: root.vertical ? Qt.Vertical : Qt.Horizontal
                from: root.from
                to: root.to
                stepSize: root.step
                value: root.value
                onMoved: root.moved(slider.value)

                background: Rectangle {
                    radius: 8
                    color: OnixTheme.mSecondaryContainer
                    implicitHeight: 16
                    implicitWidth: 16

                    Rectangle {
                        radius: 8
                        color: OnixTheme.mPrimary
                        width: slider.orientation === Qt.Horizontal ? slider.visualPosition * parent.width : parent.width
                        height: slider.orientation === Qt.Horizontal ? parent.height : slider.visualPosition * parent.height
                        y: slider.orientation === Qt.Horizontal ? 0 : parent.height - height
                    }
                }

                handle: Rectangle {
                    color: OnixTheme.mPrimary
                    radius: 20
                    border.color: OnixTheme.mSurfaceContainer
                    border.width: slider.pressed ? 4 : 6
                    implicitWidth: slider.orientation === Qt.Horizontal ? 4 : 24
                    implicitHeight: slider.orientation === Qt.Horizontal ? 24 : 4
                    x: slider.orientation === Qt.Horizontal ? slider.leftPadding + slider.visualPosition * (slider.availableWidth - width) : (slider.availableWidth - width) / 2
                    y: slider.orientation === Qt.Horizontal ? (slider.availableHeight - height) / 2 : slider.topPadding + slider.visualPosition * (slider.availableHeight - height)
                }
            }
        }

        // value bubble while dragging (horizontal only, like upstream)
        Rectangle {
            visible: slider.pressed && slider.orientation === Qt.Horizontal
            color: OnixTheme.mSurfaceContainerHigh
            radius: 20
            implicitWidth: bubbleText.implicitWidth + 32
            implicitHeight: 28
            x: 16 + slider.x + slider.leftPadding + slider.visualPosition * slider.availableWidth - implicitWidth / 2
            y: slider.y - implicitHeight - 6
            Text {
                id: bubbleText
                anchors.centerIn: parent
                text: Math.round(slider.value).toString()
                color: OnixTheme.mOnSurface
                font.pixelSize: OnixTheme.fontSmall
            }
        }
    }
}
