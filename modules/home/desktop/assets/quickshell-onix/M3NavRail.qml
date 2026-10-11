// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// M3NavRail: Material-3 navigation rail (ports upstream navigation_rail +
// its .navigation-rail styles). Vertical stack of icon-pill + label tabs;
// the selected tab gets the secondary-container pill. Drives the settings
// window tabs in P5; shown mini in the P1 smoke panel.
import QtQuick

Column {
    id: root

    property var items: []
    property int current: 0

    signal selected(int index)

    spacing: 2
    padding: 10

    Repeater {
        model: root.items
        delegate: Item {
            required property var modelData
            required property int index
            readonly property bool isCurrent: index === root.current

            implicitWidth: 76
            implicitHeight: 60

            Column {
                anchors.centerIn: parent
                spacing: 2

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: pillIcon.implicitWidth + 32
                    implicitHeight: 30
                    radius: OnixTheme.radiusFull
                    color: isCurrent ? OnixTheme.mSecondaryContainer : "transparent"

                    Text {
                        id: pillIcon
                        anchors.centerIn: parent
                        text: modelData.icon || ""
                        color: isCurrent ? OnixTheme.mOnSecondaryContainer : OnixTheme.mOnSurfaceVariant
                        font.family: OnixTheme.iconFont
                        font.pixelSize: 22
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.label || ""
                    color: OnixTheme.mOnSurfaceVariant
                    font.pixelSize: 11
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(index)
            }
        }
    }
}
