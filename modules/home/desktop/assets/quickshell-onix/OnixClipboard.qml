// Onix shell clipboard history (cliphist edition). The text/image watcher
// daemons run as user services (see the niri home module); this overlay
// lists entries newest-first, Enter copies back to the clipboard, Esc
// closes. Toggle with `quickshell --config onix ipc call onixClipboard
// toggle` (Mod+Shift+V).
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    visible: OnixUi.clipboardOpen
    focusable: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: Qt.rgba(OnixTheme.mScrim.r, OnixTheme.mScrim.g, OnixTheme.mScrim.b, 0.6)

    property var entries: []
    property int selected: 0

    onVisibleChanged: {
        if (visible) {
            root.selected = 0;
            listProc.running = true;
        }
    }

    function close(): void {
        OnixUi.clipboardOpen = false;
    }

    function copySelected(): void {
        if (root.selected < 0 || root.selected >= root.entries.length)
            return;
        var id = root.entries[root.selected].id;
        Quickshell.execDetached(["sh", "-c", "cliphist decode " + id + " | wl-copy"]);
        root.close();
    }

    Keys.onEscapePressed: root.close()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Down) {
            root.selected = Math.min(root.entries.length - 1, root.selected + 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            root.selected = Math.max(0, root.selected - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.copySelected();
            event.accepted = true;
        }
    }

    IpcHandler {
        target: "onixClipboard"
        function toggle(): void {
            OnixUi.toggleClipboard();
        }
        function open(): void {
            OnixUi.clipboardOpen = true;
        }
        function close(): void {
            root.close();
        }
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                var out = [];
                var lines = this.text.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim() === "")
                        continue;
                    var tab = lines[i].indexOf("\t");
                    if (tab < 0)
                        continue;
                    out.push({
                        id: lines[i].slice(0, tab).trim(),
                        preview: lines[i].slice(tab + 1).replace(/\n/g, " ⏎ ")
                    });
                }
                root.entries = out;
                root.selected = 0;
            }
        }
        stderr: StdioCollector {
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        anchors.centerIn: parent
        implicitWidth: 560
        implicitHeight: Math.min(480, clipCol.implicitHeight + 24)
        color: OnixTheme.mSurfaceContainerLow
        radius: 20
        border.color: OnixTheme.mOutlineVariant
        border.width: 1

        Column {
            id: clipCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 8

            Text {
                text: "Clipboard"
                color: OnixTheme.mOnSurface
                font.pixelSize: OnixTheme.fontLarge
                font.bold: true
            }

            Text {
                visible: root.entries.length === 0
                text: "Nothing copied yet."
                color: OnixTheme.mOnSurfaceVariant
                font.pixelSize: OnixTheme.fontMed
            }

            Flickable {
                visible: root.entries.length > 0
                width: parent.width
                height: Math.min(380, entryList.implicitHeight)
                contentHeight: entryList.implicitHeight
                clip: true

                Column {
                    id: entryList
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.entries
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            implicitWidth: entryList.width
                            implicitHeight: 40
                            radius: 10
                            color: root.selected === index ? OnixTheme.mSecondaryContainer : (hover.containsMouse ? OnixTheme.mSurfaceContainerHighest : "transparent")

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.preview
                                color: root.selected === index ? OnixTheme.mOnSecondaryContainer : OnixTheme.mOnSurface
                                font.pixelSize: OnixTheme.fontSmall
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selected = index;
                                    root.copySelected();
                                }
                            }
                        }
                    }
                }
            }

            Text {
                text: "enter copy · esc close"
                color: OnixTheme.mOnSurfaceVariant
                font.pixelSize: OnixTheme.fontSmall
            }
        }
    }
}
