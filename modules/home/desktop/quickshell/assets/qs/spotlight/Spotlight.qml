import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import "../theme/palette.js" as Palette

// Bare pill search bar a touch above middle. Type to filter,
// Enter runs the top hit, Esc dismisses.
PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "onix-spotlight"
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool open: false
    property bool motionOK: true

    function run(i: int): void {
        if (!open)
            return;
        SpotlightState.runItem(SpotlightState.results[i]);
        close();
    }

    function close(): void {
        if (!open)
            SpotlightState.open = false;
        open = false;
        closeTimer.restart();
    }

    onOpenChanged: {
        if (open)
            field.forceActiveFocus();
    }

    Timer {
        id: closeTimer
        interval: root.motionOK ? 250 : 50
        repeat: false
        onTriggered: SpotlightState.open = false
    }

    Process {
        id: animCheck
        command: ["hyprctl", "getoption", "animations:enabled"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.indexOf("int: 0") !== -1)
                    root.motionOK = false;
                root.open = true;
            }
        }
        onExited: {
            if (!root.open)
                root.open = true;
        }
    }

    Timer {
        id: openFallback
        interval: 500
        repeat: false
        onTriggered: {
            if (!root.open)
                root.open = true;
        }
    }

    Shortcut {
        sequence: "Up"
        enabled: root.open
        onActivated: SpotlightState.move(-1)
    }
    Shortcut {
        sequence: "Down"
        enabled: root.open
        onActivated: SpotlightState.move(1)
    }
    Shortcut {
        sequence: "Return"
        enabled: root.open
        onActivated: root.run(SpotlightState.sel)
    }
    Shortcut {
        sequence: "Enter"
        enabled: root.open
        onActivated: root.run(SpotlightState.sel)
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.close()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        onClicked: root.close()
        onWheel: wheel => SpotlightState.move(wheel.angleDelta.y > 0 ? -1 : 1)
    }

    Rectangle {
        id: card
        width: 600
        height: 60
        x: (parent.width - width) / 2
        y: parent.height * 0.38 - height / 2
        color: Palette.islandBg
        border.color: Palette.border
        border.width: 1
        radius: 999
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.97

        Behavior on opacity {
            NumberAnimation {
                duration: root.motionOK ? 180 : 0
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.motionOK ? 180 : 0
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 12

            Text {
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: Palette.muted
                text: "󰍉"
            }

            TextInput {
                id: field
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: Palette.fg
                cursorVisible: true
                onTextChanged: SpotlightState.query = text
            }
        }
    }

    Rectangle {
        width: 600
        height: resCol.implicitHeight + 14
        x: (parent.width - width) / 2
        y: card.y + card.height + 8
        color: Palette.islandBg
        border.color: Palette.border
        border.width: 1
        radius: 28
        opacity: root.open && SpotlightState.results.length > 0 ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.motionOK ? 180 : 0
            }
        }

        ColumnLayout {
            id: resCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 7
            spacing: 2

            Repeater {
                model: SpotlightState.results

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    color: index === SpotlightState.sel ? Palette.pillHover : "transparent"
                    radius: 14

                    Item {
                        x: 10
                        y: (parent.height - 30) / 2
                        width: 30
                        height: 30

                        IconImage {
                            anchors.fill: parent
                            source: modelData.icon || ""
                        }
                    }

                    Text {
                        x: 52
                        y: 7
                        width: parent.width - 64
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: Palette.fg
                        text: modelData.title
                        elide: Text.ElideRight
                    }

                    Text {
                        x: 52
                        y: 27
                        width: parent.width - 64
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Palette.muted
                        text: modelData.sub
                        elide: Text.ElideRight
                        visible: modelData.sub.length > 0
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: SpotlightState.sel = index
                        onClicked: root.run(index)
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        SpotlightState.query = "";
        SpotlightState.sel = 0;
        animCheck.running = true;
        openFallback.restart();
    }
}
