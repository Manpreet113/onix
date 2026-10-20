import QtQuick
import QtQuick.Effects
import qs.theme

// Reusable Dynamic Onix Brand Logo
// Dynamically tinted with Skein wallpaper theme colors with optional shadow/glow.
Item {
    id: root

    property real size: 24
    property color color: Theme.accent
    property bool shadow: true
    property color shadowColor: "#000000"
    property real shadowOpacity: 0.65
    property real shadowBlur: 0.5
    property real shadowOffset: 1

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    Image {
        id: logoRaw
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/brand/onix.svg")
        sourceSize: Qt.size(
            Math.max(16, Math.min(256, Math.round(root.size * 2))),
            Math.max(16, Math.min(256, Math.round(root.size * 2 * (329 / 291))))
        )
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
    }

    MultiEffect {
        id: logoEffect
        anchors.fill: logoRaw
        source: logoRaw
        colorization: 1.0
        colorizationColor: root.color

        shadowEnabled: root.shadow
        shadowColor: root.shadowColor
        shadowOpacity: root.shadowOpacity
        shadowBlur: root.shadowBlur
        shadowHorizontalOffset: root.shadowOffset
        shadowVerticalOffset: root.shadowOffset

        Behavior on colorizationColor {
            ColorAnimation { duration: Motion.effects }
        }
        Behavior on shadowColor {
            ColorAnimation { duration: Motion.effects }
        }
    }
}
