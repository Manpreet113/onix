// Onix shell keybind cheatsheet. Binds are single-sourced in the niri home
// module, which also renders ~/.config/quickshell-onix/keybinds.json for
// this view. Toggle with `quickshell --config onix ipc call onixKeybinds
// toggle` (Mod+Slash).
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    visible: OnixUi.keybindsOpen
    focusable: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: Qt.rgba(OnixTheme.mScrim.r, OnixTheme.mScrim.g, OnixTheme.mScrim.b, 0.6)

    property var groups: []

    onVisibleChanged: {
        if (visible)
            docLoader.reload();
    }

    function close(): void {
        OnixUi.keybindsOpen = false;
    }

    Keys.onEscapePressed: root.close()

    IpcHandler {
        target: "onixKeybinds"
        function toggle(): void {
            OnixUi.toggleKeybinds();
        }
        function open(): void {
            OnixUi.keybindsOpen = true;
        }
        function close(): void {
            root.close();
        }
    }

    property FileView docLoader: FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell-onix/keybinds.json"
        printErrors: false
        blockLoading: true
        onLoaded: {
            try {
                var v = JSON.parse(docLoader.text());
                root.groups = (v && v.groups) || [];
            } catch (e) {
                root.groups = [];
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        anchors.centerIn: parent
        implicitWidth: 640
        implicitHeight: Math.min(700, keysCol.implicitHeight + 24)
        color: OnixTheme.mSurfaceContainerLow
        radius: 20
        border.color: OnixTheme.mOutlineVariant
        border.width: 1

        Flickable {
            anchors.fill: parent
            anchors.margins: 12
            contentHeight: keysCol.implicitHeight
            clip: true

            Column {
                id: keysCol
                width: parent.width
                spacing: 10

                Text {
                    text: "Keybinds"
                    color: OnixTheme.mOnSurface
                    font.pixelSize: OnixTheme.fontLarge
                    font.bold: true
                }

                Repeater {
                    model: root.groups
                    delegate: Column {
                        required property var modelData
                        width: keysCol.width
                        spacing: 4

                        Text {
                            text: modelData.name || ""
                            color: OnixTheme.mPrimary
                            font.pixelSize: OnixTheme.fontMed
                            font.bold: true
                        }

                        Repeater {
                            model: modelData.binds || []
                            delegate: Row {
                                required property var modelData
                                width: keysCol.width
                                spacing: 12

                                Text {
                                    width: 220
                                    text: modelData.keys || ""
                                    color: OnixTheme.mOnSurface
                                    font.family: OnixTheme.fontFamily
                                    font.pixelSize: OnixTheme.fontSmall
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width - 232
                                    text: modelData.desc || ""
                                    color: OnixTheme.mOnSurfaceVariant
                                    font.pixelSize: OnixTheme.fontSmall
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
