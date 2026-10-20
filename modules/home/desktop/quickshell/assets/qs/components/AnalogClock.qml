import QtQuick
import qs.theme

// Caelestia / Material 3 Luxury Precision Analog Clock Dial
Item {
    id: root

    property var date: new Date()
    property real size: 74
    property bool showNumerals: size >= 120

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    readonly property int hours: date ? date.getHours() : 0
    readonly property int minutes: date ? date.getMinutes() : 0
    readonly property int seconds: date ? date.getSeconds() : 0

    readonly property real hourAngle: ((hours % 12) + minutes / 60.0 + seconds / 3600.0) * 30.0
    readonly property real minuteAngle: (minutes + seconds / 60.0) * 6.0
    readonly property real secondAngle: seconds * 6.0

    // Dial background container
    Rectangle {
        id: dial
        anchors.fill: parent
        radius: width / 2
        color: Theme.chipBg
        border.color: Theme.cardBorder
        border.width: 1
        clip: true

        Behavior on color { ColorAnimation { duration: Motion.effects } }
        Behavior on border.color { ColorAnimation { duration: Motion.effects } }

        // Concentric inner dial ring
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.86
            height: width
            radius: width / 2
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
        }

        // Concentric innermost dial ring (on large clocks)
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.52
            height: width
            radius: width / 2
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.03)
            border.width: 1
            visible: root.size >= 120
        }

        // Dial Ticks (60 ticks for large clock, 12 for compact)
        Repeater {
            model: root.size >= 120 ? 60 : 12

            delegate: Item {
                anchors.centerIn: parent
                width: dial.width
                height: dial.height
                rotation: root.size >= 120 ? (index * 6) : (index * 30)

                readonly property bool isMajor: root.size >= 120 ? (index % 5 === 0) : true
                readonly property bool isCardinal: root.size >= 120 ? (index % 15 === 0) : (index % 3 === 0)

                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: isCardinal ? 4 : (isMajor ? 5 : 6)
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: isCardinal ? Math.max(2.5, root.size * 0.015) : (isMajor ? 1.8 : 1.0)
                    height: isCardinal ? Math.max(6, root.size * 0.045) : (isMajor ? 5 : 3)
                    radius: width / 2
                    color: isCardinal ? Theme.accent : (isMajor ? Theme.text : Theme.dim)
                    opacity: isCardinal ? 1.0 : (isMajor ? 0.75 : 0.30)

                    Behavior on color { ColorAnimation { duration: Motion.effects } }
                }
            }
        }

        // Cardinal Numerals (12, 3, 6, 9) for Large Clock
        Item {
            anchors.fill: parent
            visible: root.showNumerals

            // 12
            Text {
                anchors.top: parent.top
                anchors.topMargin: root.size * 0.10
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: Theme.fontDisplay
                font.pixelSize: Math.round(root.size * 0.08)
                font.weight: Font.ExtraBold
                color: Theme.accent
                text: "12"
            }

            // 6
            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.size * 0.10
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: Theme.fontDisplay
                font.pixelSize: Math.round(root.size * 0.08)
                font.weight: Font.ExtraBold
                color: Theme.accent
                text: "6"
            }

            // 3
            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.size * 0.10
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontDisplay
                font.pixelSize: Math.round(root.size * 0.08)
                font.weight: Font.ExtraBold
                color: Theme.accent
                text: "3"
            }

            // 9
            Text {
                anchors.left: parent.left
                anchors.leftMargin: root.size * 0.10
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.fontDisplay
                font.pixelSize: Math.round(root.size * 0.08)
                font.weight: Font.ExtraBold
                color: Theme.accent
                text: "9"
            }
        }
    }

    // Hands Layer
    Item {
        anchors.fill: parent

        // 1. Hour Hand
        Item {
            anchors.centerIn: parent
            width: 1
            height: 1
            rotation: root.hourAngle

            Behavior on rotation {
                RotationAnimation {
                    duration: Motion.spatial
                    direction: RotationAnimation.Shortest
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: -Math.round(root.size * 0.04)
                width: Math.max(3, Math.round(root.size * 0.038))
                height: Math.round(root.size * 0.28)
                radius: width / 2
                color: Theme.text

                Behavior on color { ColorAnimation { duration: Motion.effects } }
            }
        }

        // 2. Minute Hand
        Item {
            anchors.centerIn: parent
            width: 1
            height: 1
            rotation: root.minuteAngle

            Behavior on rotation {
                RotationAnimation {
                    duration: Motion.spatial
                    direction: RotationAnimation.Shortest
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: -Math.round(root.size * 0.04)
                width: Math.max(2, Math.round(root.size * 0.026))
                height: Math.round(root.size * 0.38)
                radius: width / 2
                color: Theme.text

                Behavior on color { ColorAnimation { duration: Motion.effects } }
            }
        }

        // 3. Second Hand (Smooth mechanical ticking with spring bounce)
        Item {
            anchors.centerIn: parent
            width: 1
            height: 1
            rotation: root.secondAngle

            Behavior on rotation {
                RotationAnimation {
                    duration: 180
                    direction: RotationAnimation.Clockwise
                    easing.type: Easing.OutBack
                }
            }

            // Needle
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                width: Math.max(1.2, root.size * 0.012)
                height: Math.round(root.size * 0.42)
                radius: width / 2
                color: Theme.accent

                Behavior on color { ColorAnimation { duration: Motion.effects } }
            }

            // Counterbalance Tail
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                width: Math.max(1.8, root.size * 0.018)
                height: Math.round(root.size * 0.12)
                radius: width / 2
                color: Theme.accent

                Behavior on color { ColorAnimation { duration: Motion.effects } }
            }
        }

        // 4. Center Pinion Cap
        Rectangle {
            anchors.centerIn: parent
            width: Math.max(6, Math.round(root.size * 0.075))
            height: width
            radius: width / 2
            color: Theme.accent
            border.color: Theme.cardBorder
            border.width: 1

            Behavior on color { ColorAnimation { duration: Motion.effects } }

            // Inner jewel dot
            Rectangle {
                anchors.centerIn: parent
                width: Math.max(2, Math.round(parent.width * 0.35))
                height: width
                radius: width / 2
                color: Theme.textOnPrimary

                Behavior on color { ColorAnimation { duration: Motion.effects } }
            }
        }
    }
}
