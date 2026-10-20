import QtQuick
import QtQuick.Effects
import ".."

Item {
    id: root

    property real size: 24
    property color color: Theme.accent
    property bool shadow: true

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    Image {
        id: logoRaw
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/onix.svg")
        sourceSize: Qt.size(
            Math.max(16, Math.min(256, Math.round(root.size * 2))),
            Math.max(16, Math.min(256, Math.round(root.size * 2)))
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
        shadowColor: "#000000"
        shadowOpacity: 0.5
        shadowBlur: 0.4
        shadowVerticalOffset: 1

        Behavior on colorizationColor {
            ColorAnimation { duration: 200 }
        }
    }
}
