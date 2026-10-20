import QtQuick
import QtQuick.Layouts
import qs.theme

// Flat pill button for island interiors. Hover tint only, no chrome.
Rectangle {
    id: root
    color: "transparent"
    radius: 999

    property color fg: Theme.text
    property color hover: Theme.pillHover
    signal clicked
    signal rightClicked
    signal wheel(var wheel)

    Behavior on color {
        ColorAnimation {
            duration: Motion.effects
        }
    }

    default property alias content: inner.children
    implicitWidth: inner.implicitWidth + 14
    implicitHeight: inner.implicitHeight + 4

    RowLayout {
        id: inner
        anchors.centerIn: parent
        spacing: 6
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        onContainsMouseChanged: root.color = containsMouse ? root.hover : "transparent"
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
        onWheel: wheel => root.wheel(wheel)
    }
}
