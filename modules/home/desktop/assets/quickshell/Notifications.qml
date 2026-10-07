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
        onNotification: notification => { notification.tracked = true; }
    }

    Column {
        id: column
        spacing: 6

        Repeater {
            model: server.trackedNotifications
            delegate: Rectangle {
                required property var modelData
                implicitWidth: 340
                implicitHeight: body.implicitHeight + 20
                color: "#3b4252"
                radius: 8

                ColumnLayout {
                    id: body
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 2

                    Text {
                        text: modelData.summary
                        color: "#eceff4"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: modelData.body
                        color: "#d8dee9"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
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
