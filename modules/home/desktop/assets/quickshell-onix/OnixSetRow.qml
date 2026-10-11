// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixSetRow: icon / title / description + trailing control (ports upstream
// SettingsRow). Pass a Component as `control`.
import QtQuick

Item {
    id: root

    property string icon: ""
    property string title: ""
    property string description: ""
    property bool vertical: false
    property Component control: null

    implicitWidth: 800
    implicitHeight: (root.vertical ? colBody.implicitHeight : body.implicitHeight) + 16

    // horizontal: text left, control right
    Row {
        id: body
        visible: !root.vertical
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: 12

        Column {
            width: parent.width - (ctlLoader.item ? ctlLoader.implicitWidth + 12 : 0)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                visible: root.icon !== "" || root.title !== ""
                width: parent.width
                text: (root.icon !== "" ? root.icon + "  " : "") + root.title
                color: OnixTheme.mOnSurface
                font.pixelSize: OnixTheme.fontMed
                font.bold: true
                wrapMode: Text.WordWrap
            }
            Text {
                visible: root.description !== ""
                width: parent.width
                text: root.description
                color: OnixTheme.mOnSurfaceVariant
                font.pixelSize: OnixTheme.fontSmall
                wrapMode: Text.WordWrap
            }
        }

        Loader {
            id: ctlLoader
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: root.control
        }
    }

    // vertical: text full width, control below
    Column {
        id: colBody
        visible: root.vertical
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: 8

        Column {
            width: parent.width
            spacing: 2

            Text {
                visible: root.icon !== "" || root.title !== ""
                width: parent.width
                text: (root.icon !== "" ? root.icon + "  " : "") + root.title
                color: OnixTheme.mOnSurface
                font.pixelSize: OnixTheme.fontMed
                font.bold: true
                wrapMode: Text.WordWrap
            }
            Text {
                visible: root.description !== ""
                width: parent.width
                text: root.description
                color: OnixTheme.mOnSurfaceVariant
                font.pixelSize: OnixTheme.fontSmall
                wrapMode: Text.WordWrap
            }
        }

        Loader {
            sourceComponent: root.control
        }
    }
}
