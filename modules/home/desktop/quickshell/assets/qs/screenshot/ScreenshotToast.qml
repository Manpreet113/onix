import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.theme

PanelWindow {
    id: toastWin

    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: 24
        right: 24
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "onix-screenshot-toast"
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    visible: ScreenshotState.toastOpen

    implicitWidth: 360
    implicitHeight: toastCard.implicitHeight

    Rectangle {
        id: toastCard
        anchors.fill: parent
        implicitHeight: mainCol.implicitHeight + 24
        radius: 16
        color: Theme.glassBg
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        // Ambient drop shadow
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: -4
            radius: parent.radius + 2
            color: Theme.glassShadow
            opacity: 0.65
        }

        // Top specular rim
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            height: 1
            color: Theme.glassSpecular
        }

        ColumnLayout {
            id: mainCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 14
            spacing: 12

            // Top Row: Thumbnail + Info + Close
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Thumbnail Preview
                Rectangle {
                    width: 52
                    height: 52
                    radius: 8
                    color: Theme.surfaceVariant
                    border.color: Theme.cardBorder
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: ScreenshotState.lastCapturedFile.length > 0 ? ("file://" + ScreenshotState.lastCapturedFile) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                    }
                }

                // Info text
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 6
                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 14
                            color: Theme.success
                            text: "check_circle"
                        }
                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: Theme.text
                            text: "Screenshot Captured"
                        }
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 11
                        color: Theme.dim
                        text: ScreenshotState.copyToClipboard ? "Copied to clipboard" : "Saved to disk"
                    }
                }

                // Dismiss (X)
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: closeToastMouse.containsMouse ? Theme.chipHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcons
                        font.pixelSize: 16
                        color: Theme.dim
                        text: "close"
                    }

                    MouseArea {
                        id: closeToastMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ScreenshotState.toastOpen = false
                    }
                }
            }

            // Action Buttons Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Annotate Button
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: Theme.chipBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 14
                            color: Theme.accent
                            text: "edit"
                        }
                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Theme.text
                            text: "Annotate"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ScreenshotState.editLast()
                    }
                }

                // Open Image Button
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: Theme.chipBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 14
                            color: Theme.accent
                            text: "visibility"
                        }
                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Theme.text
                            text: "Open"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ScreenshotState.openLast()
                    }
                }

                // Open Folder Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    color: Theme.chipBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcons
                        font.pixelSize: 15
                        color: Theme.dim
                        text: "folder"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ScreenshotState.openFolder()
                    }
                }
            }
        }

        // Progress bar at bottom
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: parent.width * (progressAnim.running ? progressAnim.progressVal : 1)
                color: Theme.accent

                NumberAnimation on width {
                    id: progressAnim
                    property real progressVal: 1.0
                    running: ScreenshotState.toastOpen
                    from: toastCard.width
                    to: 0
                    duration: 4500
                }
            }
        }
    }
}
