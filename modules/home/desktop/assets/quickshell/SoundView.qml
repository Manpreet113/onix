import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

// Sound panel for the Overlay host: output + input device lists with
// volume sliders and mute, default-device switching, and per-app
// stream volumes. Fully reactive via PipeWire — no polling.
Item {
    id: root
    anchors.fill: parent

    signal requestClose()

    function devs(wantSink: bool): var {
        var out = [];
        if (!Pipewire.ready)
            return out;
        var vals = Pipewire.nodes.values;
        for (var i = 0; i < vals.length; i++) {
            var n = vals[i];
            if (!n || !n.audio || n.isStream)
                continue;
            if (wantSink && n.isSink)
                out.push(n);
            if (!wantSink && !n.isSink)
                out.push(n);
        }
        return out;
    }

    function streams(): var {
        var out = [];
        if (!Pipewire.ready)
            return out;
        var vals = Pipewire.nodes.values;
        for (var i = 0; i < vals.length; i++) {
            var n = vals[i];
            if (!n || !n.audio || !n.isStream)
                continue;
            var hay = ((n.description || "") + " " + (n.name || "")).toLowerCase();
            if (hay.indexOf("monitor") >= 0)
                continue;
            out.push(n);
        }
        return out;
    }

    function label(n: var): string {
        if (!n)
            return "?";
        return n.description || n.nick || n.name || "?";
    }

    PwObjectTracker {
        objects: {
            var all = root.devs(true).concat(root.devs(false)).concat(root.streams());
            if (Pipewire.defaultAudioSink)
                all.push(Pipewire.defaultAudioSink);
            if (Pipewire.defaultAudioSource)
                all.push(Pipewire.defaultAudioSource);
            return all;
        }
    }

    // volume slider row component
    component VolSlider: Item {
        id: slider
        required property var node
        implicitHeight: 26

        property real ratio: {
            if (!node || !node.audio)
                return 0;
            var v = node.audio.volume;
            return Math.max(0, Math.min(1, isNaN(v) ? 0 : v));
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Theme.bg
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * slider.ratio
            height: 6
            radius: 3
            color: slider.node && slider.node.audio && slider.node.audio.muted ? Theme.dim : Theme.blue
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width * slider.ratio - 7
            width: 14
            height: 14
            radius: 7
            color: Theme.text
            border.color: Theme.border
            border.width: 1
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPressed: mouse => slider.setAt(mouse.x)
            onPositionChanged: mouse => {
                if (mouse.buttons & Qt.LeftButton)
                    slider.setAt(mouse.x);
            }
            onWheel: wheel => {
                slider.nudge(wheel.angleDelta.y > 0 ? 0.05 : -0.05);
            }
        }

        function setAt(x: real): void {
            if (!slider.node || !slider.node.audio)
                return;
            var r = Math.max(0, Math.min(1, x / slider.width));
            slider.node.audio.volume = r;
            if (slider.node.audio.muted && r > 0)
                slider.node.audio.muted = false;
        }
        function nudge(d: real): void {
            if (!slider.node || !slider.node.audio)
                return;
            var r = Math.max(0, Math.min(1, slider.ratio + d));
            slider.node.audio.volume = r;
            if (slider.node.audio.muted && r > 0)
                slider.node.audio.muted = false;
        }
    }

    // one device row: name + default dot + mute + slider + pct
    component DevRow: Column {
        id: row
        required property var node
        property bool isDefault: false
        property string sub: ""
        property bool canDefault: false
        property bool wantSink: true
        width: parent.width
        spacing: 4

        RowLayout {
            width: parent.width
            spacing: 8

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: row.isDefault ? Theme.green : Theme.bg
                border.color: Theme.border
                border.width: 1
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                id: devName
                text: root.label(row.node)
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMed
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true

                MouseArea {
                    anchors.fill: parent
                    enabled: row.canDefault
                    onDoubleClicked: {
                        if (!row.node)
                            return;
                        if (row.wantSink)
                            Pipewire.preferredDefaultAudioSink = row.node;
                        else
                            Pipewire.preferredDefaultAudioSource = row.node;
                    }
                }
            }
            Text {
                visible: row.sub !== ""
                text: row.sub
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
            Text {
                text: {
                    if (!row.node || !row.node.audio)
                        return "";
                    if (row.node.audio.muted)
                        return "muted";
                    return Math.round((row.node.audio.volume || 0) * 100) + "%";
                }
                color: Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
                Layout.minimumWidth: 44
                horizontalAlignment: Text.AlignRight
            }
            Rectangle {
                implicitWidth: 30
                implicitHeight: 24
                radius: Theme.radiusSmall
                color: (row.node && row.node.audio && row.node.audio.muted) ? Theme.red : Theme.surface
                border.color: Theme.border
                border.width: 1
                Layout.alignment: Qt.AlignVCenter
                Text {
                    anchors.centerIn: parent
                    text: "󰝟"
                    color: (row.node && row.node.audio && row.node.audio.muted) ? Theme.bg : Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (row.node && row.node.audio)
                            row.node.audio.muted = !row.node.audio.muted;
                    }
                }
            }
        }

        VolSlider {
            width: parent.width
            node: row.node
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: body.implicitHeight
        clip: true

        Column {
            id: body
            width: parent.width
            spacing: 14

            Text {
                text: "Sound"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLarge
                font.bold: true
            }

            Text {
                visible: !Pipewire.ready
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "pipewire not ready"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMed
            }

            Text {
                text: "output · double-click to set default"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
            Repeater {
                model: root.devs(true)
                delegate: DevRow {
                    required property var modelData
                    node: modelData
                    isDefault: modelData === Pipewire.defaultAudioSink
                    sub: isDefault ? "default" : ""
                    canDefault: true
                    wantSink: true
                }
            }

            Text {
                text: "input · double-click to set default"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
            Repeater {
                model: root.devs(false)
                delegate: DevRow {
                    required property var modelData
                    node: modelData
                    isDefault: modelData === Pipewire.defaultAudioSource
                    sub: isDefault ? "default" : ""
                    canDefault: true
                    wantSink: false
                }
            }

            Text {
                visible: root.streams().length > 0
                text: "apps"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
            Repeater {
                model: root.streams()
                delegate: DevRow {
                    required property var modelData
                    node: modelData
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "drag slider · wheel ±5 · click speaker to mute · esc close"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
        }
    }
}
