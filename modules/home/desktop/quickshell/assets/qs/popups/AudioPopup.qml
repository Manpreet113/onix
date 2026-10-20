import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.components
import qs.theme

// Ambxst / Caelestia Inspired Luxury Audio & PipeWire Sink Pop-up
Rectangle {
    id: root
    width: 350
    implicitHeight: mainCol.implicitHeight + 28
    height: implicitHeight

    property bool embedded: false
    property var sink: Pipewire.defaultAudioSink
    property real vol: sink?.audio.volume ?? 0
    property bool muted: sink?.audio.muted ?? false

    color: embedded ? "transparent" : Theme.glassBg
    border.color: embedded ? "transparent" : Theme.glassBorder
    border.width: embedded ? 0 : 1
    radius: embedded ? 0 : 20
    clip: true

    // Specular top highlight
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: 1
        color: Theme.glassSpecular
        visible: !root.embedded
    }

    // Ambient drop shadow
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: -4
        radius: parent.radius + 2
        color: Theme.glassShadow
        opacity: 0.6
        visible: !root.embedded
    }

    // Dynamic Sinks List Model
    ListModel {
        id: sinksModel
    }

    Process {
        id: sinksProc
        command: ["sh", "-c", "wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -E '^[ │*]+[0-9]+\\.'"]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line) return;
                const isDefault = line.includes("*");
                const clean = line.replace(/^[│* ]+/, "");
                const match = clean.match(/^([0-9]+)\.\s+(.+?)(?:\s+\[vol:.*\])?$/);
                if (match) {
                    const id = parseInt(match[1], 10);
                    let name = match[2].trim();
                    // Clean up lengthy ALSA card names
                    name = name.replace(/^Raptor Lake-[^ ]+\s+/, "")
                               .replace(/cAVS\s+/, "")
                               .replace(/\s+\(Stereo\)$/, "");
                    let icon = "speaker";
                    if (name.toLowerCase().includes("headphone") || name.toLowerCase().includes("buds"))
                        icon = "headphones";
                    else if (name.toLowerCase().includes("hdmi") || name.toLowerCase().includes("displayport"))
                        icon = "tv";
                    
                    sinksModel.append({
                        sinkId: id,
                        sinkName: name,
                        isDefault: isDefault,
                        sinkIcon: icon
                    });
                }
            }
        }
    }

    function refreshSinks(): void {
        sinksModel.clear();
        if (!sinksProc.running)
            sinksProc.running = true;
    }

    Component.onCompleted: refreshSinks()

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        spacing: 14

        // 1. Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 10
                color: Theme.chipBg
                border.color: Theme.cardBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.muted ? Theme.error : Theme.accent
                    text: root.muted ? "volume_off" : (root.vol > 0.5 ? "volume_up" : "volume_down")
                }
            }

            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Theme.text
                    text: "Audio & Output"
                }

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    color: Theme.dim
                    text: root.muted ? "Muted" : (Math.round(root.vol * 100) + "% Master Volume")
                }
            }

            // Mute / Unmute Button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 10
                color: root.muted ? Theme.error : Theme.chipBg
                border.color: root.muted ? Theme.error : Theme.cardBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.muted ? Theme.textOnPrimary : Theme.text
                    text: root.muted ? "volume_off" : "volume_up"
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.sink?.audio)
                            root.sink.audio.muted = !root.sink.audio.muted;
                    }
                }
            }
        }

        // 2. Tactile Master Volume Slider Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 12
            color: Theme.cardBg
            border.color: Theme.cardBorder
            border.width: 1
            clip: true

            // Interactive Fill Bar
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: Math.max(0, Math.min(parent.width, parent.width * Math.min(1.0, root.vol)))
                radius: parent.radius
                color: root.muted ? Theme.error : Theme.accent
                opacity: root.muted ? 0.35 : 0.85

                Behavior on width {
                    NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
                }
            }

            // Slider Content Overlay
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14

                Text {
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: root.muted ? Theme.error : (root.vol > 0.15 ? Theme.textOnPrimary : Theme.text)
                    text: root.muted ? "volume_off" : (root.vol > 0.5 ? "volume_up" : "volume_down")
                }

                Item { Layout.fillWidth: true }

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: root.muted ? Theme.error : (root.vol > 0.85 ? Theme.textOnPrimary : Theme.text)
                    text: Math.round(root.vol * 100) + "%"
                }
            }

            // Drag / Click MouseArea
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function setVolFromX(mouseX: real, width: real): void {
                    if (!root.sink?.audio) return;
                    const next = Math.max(0.0, Math.min(1.5, mouseX / width));
                    root.sink.audio.volume = next;
                    if (root.muted) root.sink.audio.muted = false;
                }

                onPositionChanged: mouse => {
                    if (pressed) setVolFromX(mouse.x, width);
                }
                onPressed: mouse => setVolFromX(mouse.x, width)
                onWheel: wheel => {
                    if (!root.sink?.audio) return;
                    const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    root.sink.audio.volume = Math.max(0.0, Math.min(1.5, root.vol + delta));
                    if (root.muted) root.sink.audio.muted = false;
                }
            }
        }

        // 3. Quick Volume Preset Chips
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { label: "Mute", vol: 0, isMute: true },
                    { label: "25%", vol: 0.25, isMute: false },
                    { label: "50%", vol: 0.50, isMute: false },
                    { label: "75%", vol: 0.75, isMute: false },
                    { label: "100%", vol: 1.0, isMute: false }
                ]

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    radius: 7
                    color: presetMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                    border.color: presetMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Theme.cardBorder
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Motion.snappy } }
                    Behavior on border.color { ColorAnimation { duration: Motion.snappy } }

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontPrimary
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: Theme.text
                        text: modelData.label
                    }

                    MouseArea {
                        id: presetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.sink?.audio) return;
                            if (modelData.isMute) {
                                root.sink.audio.muted = true;
                            } else {
                                root.sink.audio.muted = false;
                                root.sink.audio.volume = modelData.vol;
                            }
                        }
                    }
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.cardBorder
        }

        // 4. Output Device Sinks List
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.dim
                    text: "OUTPUT DEVICE"
                }

                Item { Layout.fillWidth: true }

                Text {
                    font.family: Theme.fontIcons
                    font.pixelSize: 14
                    color: Theme.dim
                    text: "refresh"

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.refreshSinks()
                    }
                }
            }

            Repeater {
                model: sinksModel

                delegate: Rectangle {
                    required property var model
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 10
                    color: model.isDefault ? Theme.chipHover : Theme.cardBg
                    border.color: model.isDefault ? Theme.accent : Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 18
                            color: model.isDefault ? Theme.accent : Theme.dim
                            text: model.sinkIcon
                        }

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 12
                            font.weight: model.isDefault ? Font.Bold : Font.Normal
                            color: model.isDefault ? Theme.text : Theme.subtext
                            text: model.sinkName
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Checkmark for default
                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 16
                            color: Theme.accent
                            text: "check"
                            visible: model.isDefault
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["wpctl", "set-default", model.sinkId.toString()]);
                            // Refresh list after brief delay
                            refreshTimer.restart();
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 300
        repeat: false
        onTriggered: root.refreshSinks()
    }
}
