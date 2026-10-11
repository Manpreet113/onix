// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixSegmented: connected button group (ports make_toggle_buttons /
// make_independent_toggle_buttons + .connected-button-group styles).
// model: [{label, icon, value}]; the matching entry renders filled.
// Values compare by JSON so anchor arrays work.
import QtQuick

Row {
    id: root

    property var model: []
    property var current: null
    // multi: current is an array of on-values (independent toggles)
    property bool multi: false
    signal picked(var value)

    function same(a, b): bool {
        return JSON.stringify(a) === JSON.stringify(b);
    }

    spacing: 2

    Repeater {
        model: root.model
        delegate: Rectangle {
            required property var modelData
            required property int index
            readonly property int count: root.model.length
            readonly property bool isCurrent: root.multi ? (root.current || []).indexOf(modelData.value) >= 0 : root.same(modelData.value, root.current)

            implicitWidth: contentRow.implicitWidth + 20
            implicitHeight: 32
            color: isCurrent ? OnixTheme.mPrimary : "transparent"
            radius: 8
            topLeftRadius: index === 0 ? 20 : 8
            bottomLeftRadius: index === 0 ? 20 : 8
            topRightRadius: index === count - 1 ? 20 : 8
            bottomRightRadius: index === count - 1 ? 20 : 8

            Behavior on color {
                NumberAnimation {
                    duration: OnixTheme.fadeFast
                }
            }

            Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: 6
                Text {
                    visible: (modelData.icon || "") !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.icon
                    color: isCurrent ? OnixTheme.mOnPrimary : OnixTheme.mOnSurface
                    font.family: OnixTheme.iconFont
                    font.pixelSize: 18
                }
                Text {
                    visible: (modelData.label || "") !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    color: isCurrent ? OnixTheme.mOnPrimary : OnixTheme.mOnSurface
                    font.pixelSize: OnixTheme.fontSmall
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(modelData.value)
            }
        }
    }
}
