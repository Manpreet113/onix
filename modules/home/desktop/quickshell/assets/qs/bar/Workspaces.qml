import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.services
import qs.theme

// Caelestia Material 3 Fluid Sliding Workspaces Capsule
Item {
    id: root
    implicitWidth: wsContainer.implicitWidth
    implicitHeight: 28

    // Ensure at least workspaces 1..5 are available to click/navigate
    readonly property var activeWsMap: {
        const map = {};
        for (let ws of Hyprland.workspaces.values) {
            map[ws.id] = {
                active: ws.active,
                windows: ws.toplevels?.values?.length ?? 0
            };
        }
        return map;
    }

    readonly property int currentActiveId: {
        for (let ws of Hyprland.workspaces.values) {
            if (ws.active) return ws.id;
        }
        return 1;
    }

    readonly property var wsIds: {
        const maxId = Math.max(5, ...Hyprland.workspaces.values.map(w => w.id));
        const arr = [];
        for (let i = 1; i <= Math.min(10, Math.max(5, maxId)); i++) {
            arr.push(i);
        }
        return arr;
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            const cur = root.currentActiveId;
            const next = wheel.angleDelta.y > 0
                ? Math.max(1, cur - 1)
                : Math.min(10, cur + 1);
            Hypr.focusWorkspace(next);
        }
    }

    Rectangle {
        id: wsContainer
        anchors.centerIn: parent
        implicitWidth: wsRow.implicitWidth + 12
        implicitHeight: 28
        radius: 14
        color: Qt.rgba(1, 1, 1, 0.04)
        border.color: Qt.rgba(1, 1, 1, 0.06)
        border.width: 1

        RowLayout {
            id: wsRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: root.wsIds

                delegate: Item {
                    id: wsItem
                    required property int modelData

                    readonly property int wsId: modelData
                    readonly property var wsInfo: root.activeWsMap[wsId] ?? null
                    readonly property bool isActive: (root.currentActiveId === wsId)
                    readonly property bool isOccupied: (wsInfo && wsInfo.windows > 0)
                    readonly property bool isHovered: wsMouse.containsMouse

                    Layout.preferredWidth: {
                        if (isActive) return 30;
                        if (isHovered) return 20;
                        if (isOccupied) return 18;
                        return 10;
                    }
                    Layout.preferredHeight: 22
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on Layout.preferredWidth {
                        SpringAnimation {
                            spring: Motion.springStiffness
                            damping: Motion.springDamping
                        }
                    }

                    Rectangle {
                        id: wsPill
                        anchors.fill: parent
                        radius: 11

                        color: {
                            if (wsItem.isActive) return Theme.accent;
                            if (wsItem.isHovered) return Qt.rgba(1, 1, 1, 0.14);
                            if (wsItem.isOccupied) return Qt.rgba(1, 1, 1, 0.08);
                            return "transparent";
                        }
                        border.color: wsItem.isActive ? Qt.rgba(1, 1, 1, 0.25) : "transparent"
                        border.width: wsItem.isActive ? 1 : 0

                        Behavior on color { ColorAnimation { duration: Motion.effects } }

                        // Content inside workspace pill
                        Text {
                            anchors.centerIn: parent
                            visible: wsItem.isActive || wsItem.isOccupied
                            text: wsItem.wsId.toString()
                            font.family: Theme.fontPrimary
                            font.pixelSize: wsItem.isActive ? 11 : 10
                            font.weight: wsItem.isActive ? Font.Bold : Font.DemiBold
                            color: wsItem.isActive ? Theme.chipActiveText : Theme.text
                            opacity: wsItem.isActive ? 1.0 : (wsItem.isHovered ? 0.95 : 0.70)
                        }

                        // Dot for empty inactive workspace
                        Rectangle {
                            anchors.centerIn: parent
                            visible: !wsItem.isActive && !wsItem.isOccupied
                            width: wsItem.isHovered ? 6 : 4
                            height: width
                            radius: width / 2
                            color: Theme.text
                            opacity: wsItem.isHovered ? 0.60 : 0.25

                            Behavior on width { NumberAnimation { duration: Motion.snappy } }
                            Behavior on opacity { NumberAnimation { duration: Motion.snappy } }
                        }
                    }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hypr.focusWorkspace(wsItem.wsId)
                    }
                }
            }
        }
    }
}
