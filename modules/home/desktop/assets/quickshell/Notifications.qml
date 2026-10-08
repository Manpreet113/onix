import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

PanelWindow {
    id: popup

    anchors {
        top: true
        right: true
    }
    margins {
        top: 40
        right: 10
    }
    implicitWidth: 340
    implicitHeight: column.implicitHeight
    color: "transparent"

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: notification => {
            NotifHistory.push(notification);
            notification.tracked = true;
        }
    }

    Column {
        id: column
        spacing: 6

        Repeater {
            model: server.trackedNotifications
            delegate: Rectangle {
                required property var modelData
                visible: !Prefs.dnd
                implicitWidth: 340
                implicitHeight: body.implicitHeight + 20
                color: Theme.surface
                radius: 8

                ColumnLayout {
                    id: body
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 2

                    Text {
                        text: modelData.summary
                        color: Theme.text
                        font.pixelSize: Theme.fontMed
                        font.bold: true
                        font.family: Theme.fontFamily
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: modelData.body
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSmall
                        font.family: Theme.fontFamily
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                Timer {
                    interval: modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000
                    running: true
                    repeat: false
                    onTriggered: modelData.expire()
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: modelData.expire()
                }
            }
        }
    }
}
