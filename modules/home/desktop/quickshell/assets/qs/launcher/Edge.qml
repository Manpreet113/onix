import QtQuick
import Quickshell
import Quickshell.Wayland

// 4px sentinel strip on the right edge: lingering here unfolds the fan.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        right: true
    }
    implicitWidth: 4
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: false
    color: "transparent"
    mask: Region {
        item: strip
    }
    WlrLayershell.namespace: "onix-edge"

    Rectangle {
        id: strip
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
            onEntered: dwell.restart()
            onExited: dwell.stop()
        }
    }

    Timer {
        id: dwell
        interval: 350
        repeat: false
        onTriggered: {
            if (!LauncherState.open)
                LauncherState.open = true;
        }
    }
}
