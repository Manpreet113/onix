import QtQuick
import QtQuick.Layouts

// Flat pill button for island interiors. Hover tint only, no chrome.
Rectangle {
    id: root
    color: "transparent"
    radius: 999

    property color fg: "#F2F2F2"
    property color hover: "#40777777"
    signal clicked
    signal rightClicked

    default property alias content: inner.children
    implicitWidth: inner.implicitWidth + 22
    implicitHeight: inner.implicitHeight + 10

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
    }
}
