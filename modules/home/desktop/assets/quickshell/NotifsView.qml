import QtQuick
import QtQuick.Layouts
import Quickshell

// Notification center content for the Overlay host: history list,
// do-not-disturb toggle, clear-all. History comes from NotifHistory
// (recorded on post, independent of popup expiry).
Item {
    id: root
    anchors.fill: parent

    Column {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            width: parent.width
            spacing: 12

            Text {
                text: "Notifications"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLarge
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: 86
                implicitHeight: 26
                radius: 13
                color: Prefs.dnd ? Theme.error : Theme.surface
                border.color: Theme.border
                border.width: 1
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.fadeFast
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: Prefs.dnd ? "DND on" : "DND off"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Prefs.toggleDnd()
                }
            }

            Rectangle {
                implicitWidth: 70
                implicitHeight: 26
                radius: 13
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Clear"
                    color: Theme.subtext
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: NotifHistory.clear()
                }
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Prefs.dnd ? "do not disturb is on — new notifications stay silent" : "click an entry to dismiss it"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - 110
            clip: true
            spacing: 8
            model: NotifHistory.items

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: list.width
                implicitHeight: Math.max(56, entryBody.implicitHeight + 20)
                color: Theme.surface
                radius: Theme.radiusMed

                Column {
                    id: entryBody
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 2

                    RowLayout {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: modelData.app || "app"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: modelData.time ? Qt.formatDateTime(new Date(modelData.time), "HH:mm") : ""
                            color: Theme.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                    Text {
                        width: parent.width
                        text: modelData.summary || ""
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontMed
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: modelData.body || ""
                        color: Theme.subtext
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: NotifHistory.removeAt(index)
                }
            }
        }

        Text {
            visible: NotifHistory.items.length === 0
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "nothing here yet"
            color: Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMed
        }
    }
}
