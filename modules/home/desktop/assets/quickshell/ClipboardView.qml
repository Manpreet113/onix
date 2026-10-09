import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Clipboard panel for the Overlay host: cliphist history with search,
// click-to-copy, per-entry delete and full wipe.
Item {
    id: root
    anchors.fill: parent

    signal requestClose()

    property string query: ""
    property var entries: []

    function refresh(): void {
        listProc.running = true;
    }

    function onShown(): void {
        searchBox.text = "";
        root.query = "";
        root.refresh();
    }

    function filtered(): var {
        var q = root.query.trim().toLowerCase();
        var out = [];
        for (var i = 0; i < root.entries.length; i++) {
            var e = root.entries[i];
            if (q.length === 0 || e.preview.toLowerCase().indexOf(q) >= 0)
                out.push(e);
        }
        return out;
    }

    function copyEntry(id: string): void {
        Quickshell.execDetached(["sh", "-c", "cliphist decode " + id + " | wl-copy"]);
        root.requestClose();
    }

    function deleteEntry(id: string): void {
        Quickshell.execDetached(["sh", "-c", "cliphist delete " + id]);
        delTimer.restart();
    }

    function wipe(): void {
        Quickshell.execDetached(["cliphist", "wipe"]);
        root.entries = [];
    }

    Timer {
        id: delTimer
        interval: 400
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = [];
                var lines = this.text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    if (line.length === 0)
                        continue;
                    var tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    out.push({ id: line.slice(0, tab), preview: line.slice(tab + 1) });
                }
                root.entries = out;
            }
        }
        stderr: StdioCollector {}
    }

    function focusView(): void {
        searchBox.forceActiveFocus();
    }

    Column {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            width: parent.width
            spacing: 12

            Text {
                text: "Clipboard"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLarge
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: 70
                implicitHeight: 26
                radius: 13
                color: Theme.surface
                border.color: Theme.border
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "wipe"
                    color: Theme.red
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.wipe()
                }
            }
        }

        TextInput {
            id: searchBox
            width: parent.width
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMed
            selectByMouse: true
            onTextChanged: root.query = text
            Keys.onReturnPressed: {
                var m = root.filtered();
                if (m.length > 0)
                    root.copyEntry(m[0].id);
            }
            Keys.onEnterPressed: {
                var n = root.filtered();
                if (n.length > 0)
                    root.copyEntry(n[0].id);
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -8
                color: Theme.surface
                radius: Theme.radiusMed
                z: -1
            }
            Text {
                anchors.fill: parent
                text: "search history…"
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMed
                visible: searchBox.text.length === 0
            }
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - 150
            clip: true
            spacing: 6
            model: root.filtered()

            delegate: Rectangle {
                required property var modelData
                width: list.width
                implicitHeight: Math.max(40, entryText.implicitHeight + 18)
                color: entryMouse.containsMouse ? Theme.bg : Theme.surface
                radius: Theme.radiusSmall
                border.color: Theme.border
                border.width: 1
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.fadeFast
                    }
                }

                // below the row content so the ✕ button stays clickable
                MouseArea {
                    id: entryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.copyEntry(modelData.id)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        id: entryText
                        text: modelData.preview
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontMed
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "✕"
                        color: entryMouse.containsMouse ? Theme.red : Theme.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            onClicked: root.deleteEntry(modelData.id)
                        }
                    }
                }

                // (entryMouse is declared first so it stays below)
            }
        }

        Text {
            visible: root.entries.length === 0
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "history is empty"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMed
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "click copies + closes · ✕ deletes · enter copies first · esc close"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }
}
