// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixMenu: shared context menu (replaces upstream Gtk PopoverMenus).
// Singleton — one menu at a time. open(anchorItem, items) places the card
// under the anchor; items are {label, enabled, separator, fire}. Backdrop
// click or selection closes.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    visible: false
    focusable: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    property var items: []
    property real cardX: 0
    property real cardY: 0

    function open(anchorItem, model): void {
        root.items = model || [];
        var p = { x: 200, y: 200 };
        try {
            p = anchorItem.mapToGlobal(0, anchorItem.height + 4);
        } catch (e) {
        }
        var maxW = 1920;
        try {
            maxW = Quickshell.screens.values[0].width;
        } catch (e) {
        }
        root.cardX = Math.max(8, Math.min(p.x, maxW - 240));
        root.cardY = Math.max(8, p.y);
        root.visible = true;
    }

    function close(): void {
        root.visible = false;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        x: root.cardX
        y: root.cardY
        implicitWidth: 220
        implicitHeight: menuCol.implicitHeight + 12
        color: OnixTheme.mSurfaceContainer
        radius: 15
        border.color: Qt.rgba(OnixTheme.mOutlineVariant.r, OnixTheme.mOutlineVariant.g, OnixTheme.mOutlineVariant.b, 0.5)
        border.width: 1

        Column {
            id: menuCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 6
            }
            spacing: 2

            Repeater {
                model: root.items
                delegate: Item {
                    required property var modelData
                    required property int index
                    implicitWidth: 208
                    implicitHeight: modelData.separator ? 9 : 32

                    Rectangle {
                        visible: modelData.separator === true
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: 1
                        color: OnixTheme.mOutlineVariant
                    }

                    Rectangle {
                        visible: modelData.separator !== true
                        anchors.fill: parent
                        radius: 10
                        color: mArea.containsMouse && modelData.enabled !== false ? OnixTheme.mSurfaceContainerHighest : "transparent"

                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 12
                                rightMargin: 12
                            }
                            text: modelData.label || ""
                            color: modelData.enabled === false ? OnixTheme.mOnSurfaceVariant : OnixTheme.mOnSurface
                            font.pixelSize: OnixTheme.fontSmall
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: mArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: modelData.enabled === false ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.enabled === false)
                                    return;
                                var fn = modelData.fire;
                                root.close();
                                if (fn)
                                    fn();
                            }
                        }
                    }
                }
            }
        }
    }
}
