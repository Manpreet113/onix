import QtQuick
import QtQuick.Layouts

// Floating pill island: translucent card, hairline border, fully round.
// Sized by content via implicit bindings (no anchors.fill circularity).
Rectangle {
    id: root
    color: "#D6060606"
    border.color: "#2B2B2B"
    border.width: 1
    radius: 999

    implicitWidth: inner.implicitWidth + 16
    implicitHeight: inner.implicitHeight + 8

    default property alias content: inner.children

    RowLayout {
        id: inner
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        spacing: 6
    }
}
