// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixNotifCard: shared notification card (ports upstream ExoNotification).
// Icon / summary / • / relative age / expandable body / action buttons /
// close. Compact mode collapses to one line without age, actions, or
// expand. Center snapshots carry no live actions, so action buttons render
// only when an actions model is supplied.
import QtQuick
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root

    property string summary: ""
    property string body: ""
    property string iconName: ""
    property double born: 0
    property bool compact: false
    property var actions: null

    signal dismissed()
    signal actionFired(var action)

    property bool expanded: false
    property string ageText: ""

    function relativeTime(ts): string {
        var diff = Math.floor(Date.now() / 1000 - ts);
        if (diff < 60)
            return "now";
        if (diff < 3600)
            return Math.floor(diff / 60) + "m";
        if (diff < 86400)
            return Math.floor(diff / 3600) + "h";
        return Math.floor(diff / 86400) + "d";
    }

    function refreshAge(): void {
        root.ageText = root.relativeTime(root.born);
    }

    implicitWidth: 360
    implicitHeight: inner.implicitHeight + 24
    color: OnixTheme.mSurfaceContainer
    radius: OnixTheme.radiusLarge
    border.color: OnixTheme.mOutlineVariant
    border.width: 1

    Component.onCompleted: root.refreshAge()

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshAge()
    }

    Row {
        id: inner
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 10

        Item {
            width: root.compact ? 16 : 28
            height: root.compact ? 16 : 28
            anchors.top: parent.top
            Text {
                anchors.fill: parent
                text: "notifications"
                color: OnixTheme.mOnSurfaceVariant
                font.family: OnixTheme.iconFont
                font.pixelSize: root.compact ? 16 : 24
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            IconImage {
                anchors.fill: parent
                visible: root.iconName !== ""
                source: Quickshell.iconPath(root.iconName, "")
            }
        }

        Column {
            width: inner.width - 38 - btnCol.width - 20
            spacing: root.compact ? 8 : 2

            Row {
                spacing: 5
                Text {
                    text: root.summary
                    color: OnixTheme.mOnSurface
                    font.pixelSize: OnixTheme.fontMed
                    font.bold: true
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, parent.parent.width - (root.compact ? 0 : ageRow.width + 10))
                }
                Row {
                    id: ageRow
                    visible: !root.compact
                    spacing: 5
                    Text {
                        text: "•"
                        color: OnixTheme.mOnSurfaceVariant
                        font.pixelSize: OnixTheme.fontSmall
                    }
                    Text {
                        text: root.ageText
                        color: OnixTheme.mOnSurfaceVariant
                        font.pixelSize: OnixTheme.fontSmall
                    }
                }
            }

            Text {
                visible: root.body !== ""
                text: root.body
                color: OnixTheme.mOnSurfaceVariant
                font.pixelSize: OnixTheme.fontSmall
                wrapMode: root.expanded ? Text.WordWrap : Text.NoWrap
                elide: root.expanded ? Text.ElideNone : Text.ElideRight
                maximumLineCount: (root.expanded || root.compact) ? 1 : 3
                width: parent.width
                textFormat: Text.RichText
            }

            Row {
                visible: !root.compact && root.actions !== null && root.actions.length > 0
                spacing: 4
                Repeater {
                    model: root.actions
                    delegate: M3Button {
                        required property var modelData
                        btnType: "text"
                        size: "xs"
                        label: modelData.text || ""
                        onClicked: root.actionFired(modelData)
                    }
                }
            }
        }

        Column {
            id: btnCol
            spacing: 5
            M3Button {
                btnType: "text"
                size: "xs"
                icon: "close"
                onClicked: root.dismissed()
            }
            M3Button {
                visible: !root.compact && root.body !== ""
                btnType: "text"
                size: "xs"
                icon: root.expanded ? "arrow_drop_up" : "arrow_drop_down"
                onClicked: root.expanded = !root.expanded
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.dismissed()
    }
}
