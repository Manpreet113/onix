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
            color: slider.node && slider.node.audio && slider.node.audio.muted ? Theme.dim : Theme.primary
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

    // channel fader: vertical mixer strip for one device
    component Fader: Column {
        id: fader
        required property var node
        property bool isDefault: false
        property bool canDefault: false
        property bool wantSink: true
        width: 110
        spacing: 6

        property real ratio: {
            if (!node || !node.audio)
                return 0;
            var v = node.audio.volume;
            return Math.max(0, Math.min(1, isNaN(v) ? 0 : v));
        }

        function setAt(y: real, h: real): void {
            if (!fader.node || !fader.node.audio || h <= 0)
                return;
            var r = Math.max(0, Math.min(1, 1 - y / h));
            fader.node.audio.volume = r;
            if (fader.node.audio.muted && r > 0)
                fader.node.audio.muted = false;
        }

        function nudge(d: real): void {
            if (!fader.node || !fader.node.audio)
                return;
            var r = Math.max(0, Math.min(1, fader.ratio + d));
            fader.node.audio.volume = r;
            if (fader.node.audio.muted && r > 0)
                fader.node.audio.muted = false;
        }

        function toggleMute(): void {
            if (fader.node && fader.node.audio)
                fader.node.audio.muted = !fader.node.audio.muted;
        }

        function makeDefault(): void {
            if (!fader.node || !fader.canDefault)
                return;
            if (fader.wantSink)
                Pipewire.preferredDefaultAudioSink = fader.node;
            else
                Pipewire.preferredDefaultAudioSource = fader.node;
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.label(fader.node)
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true
            elide: Text.ElideRight
            maximumLineCount: 1

            MouseArea {
                anchors.fill: parent
                enabled: fader.canDefault
                onDoubleClicked: fader.makeDefault()
            }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: fader.isDefault ? "default" : (fader.node && fader.node.audio && fader.node.audio.muted ? "muted" : Math.round(fader.ratio * 100) + "%")
            color: fader.isDefault ? Theme.success : Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }

        Item {
            id: channel
            width: 30
            height: 130
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.fill: parent
                radius: 7
                color: Theme.bg
                border.color: Theme.border
                border.width: 1
            }
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 3
                height: Math.max(0, (parent.height - 6) * fader.ratio)
                radius: 5
                color: (fader.node && fader.node.audio && fader.node.audio.muted) ? Theme.dim : Theme.primary
            }
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: -7
                anchors.right: parent.right
                anchors.rightMargin: -7
                y: (parent.height - 6) * (1 - fader.ratio) - 1
                height: 10
                radius: 3
                color: Theme.text
                border.color: Theme.border
                border.width: 1
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPressed: mouse => fader.setAt(mouse.y, channel.height)
                onPositionChanged: mouse => {
                    if (mouse.buttons & Qt.LeftButton)
                        fader.setAt(mouse.y, channel.height);
                }
                onWheel: wheel => {
                    fader.nudge(wheel.angleDelta.y > 0 ? 0.05 : -0.05);
                }
                onDoubleClicked: fader.makeDefault()
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: 56
            implicitHeight: 24
            radius: Theme.radiusSmall
            color: (fader.node && fader.node.audio && fader.node.audio.muted) ? Theme.error : Theme.surface
            border.color: Theme.border
            border.width: 1
            Text {
                anchors.centerIn: parent
                text: (fader.node && fader.node.audio && fader.node.audio.muted) ? "mut" : "mute"
                color: (fader.node && fader.node.audio && fader.node.audio.muted) ? Theme.bg : Theme.subtext
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                onClicked: fader.toggleMute()
            }
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
                color: row.isDefault ? Theme.success : Theme.bg
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
                color: (row.node && row.node.audio && row.node.audio.muted) ? Theme.error : Theme.surface
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
                text: "output · double-click a fader to set default"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
            Item {
                width: parent.width
                implicitHeight: 250
                Row {
                    anchors.centerIn: parent
                    spacing: 20
                    Repeater {
                        model: root.devs(true)
                        delegate: Fader {
                            required property var modelData
                            node: modelData
                            isDefault: modelData === Pipewire.defaultAudioSink
                            canDefault: true
                            wantSink: true
                        }
                    }
                }
            }

            Text {
                text: "input · double-click a fader to set default"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
            Item {
                width: parent.width
                implicitHeight: root.devs(false).length > 0 ? 250 : 0
                visible: root.devs(false).length > 0
                Row {
                    anchors.centerIn: parent
                    spacing: 20
                    Repeater {
                        model: root.devs(false)
                        delegate: Fader {
                            required property var modelData
                            node: modelData
                            isDefault: modelData === Pipewire.defaultAudioSource
                            canDefault: true
                            wantSink: false
                        }
                    }
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
                text: "drag fader · wheel ±5 · double-click sets default · esc close"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
            }
        }
    }
}
