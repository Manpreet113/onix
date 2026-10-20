import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme

Rectangle {
    id: root

    implicitHeight: 48
    implicitWidth: hudRow.implicitWidth + 24
    radius: 24

    color: Theme.glassBg
    border.color: Theme.glassBorder
    border.width: 1

    // Ambient drop shadow
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: -4
        radius: root.radius + 2
        color: Theme.glassShadow
        opacity: 0.65
    }

    // Top specular rim
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 1
        color: Theme.glassSpecular
    }

    RowLayout {
        id: hudRow
        anchors.centerIn: parent
        spacing: 8

        // ==========================================
        // 1. CAPTURE MODES
        // ==========================================
        RowLayout {
            spacing: 4

            // Region Mode
            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: ScreenshotState.mode === "region" ? Theme.accent : (regionMouse.containsMouse ? Theme.chipHover : "transparent")

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: ScreenshotState.mode === "region" ? Theme.background : Theme.text
                    text: "crop"
                }

                MouseArea {
                    id: regionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ScreenshotState.mode = "region"
                }
            }

            // Window Mode
            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: ScreenshotState.mode === "window" ? Theme.accent : (winMouse.containsMouse ? Theme.chipHover : "transparent")

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: ScreenshotState.mode === "window" ? Theme.background : Theme.text
                    text: "window"
                }

                MouseArea {
                    id: winMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ScreenshotState.mode = "window"
                }
            }

            // Fullscreen Mode
            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: ScreenshotState.mode === "fullscreen" ? Theme.accent : (fullMouse.containsMouse ? Theme.chipHover : "transparent")

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: ScreenshotState.mode === "fullscreen" ? Theme.background : Theme.text
                    text: "fullscreen"
                }

                MouseArea {
                    id: fullMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ScreenshotState.mode = "fullscreen"
                }
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 22
            color: Theme.glassBorder
            Layout.leftMargin: 4
            Layout.rightMargin: 4
        }

        // ==========================================
        // 2. DESTINATION & OPTIONS
        // ==========================================
        RowLayout {
            spacing: 6

            // Clipboard Toggle
            Rectangle {
                height: 32
                implicitWidth: clipRow.implicitWidth + 18
                radius: 16
                color: ScreenshotState.copyToClipboard ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Theme.chipBg
                border.color: ScreenshotState.copyToClipboard ? Theme.accent : Theme.cardBorder
                border.width: 1

                RowLayout {
                    id: clipRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 15
                        color: ScreenshotState.copyToClipboard ? Theme.accent : Theme.dim
                        text: "content_copy"
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: ScreenshotState.copyToClipboard ? Theme.text : Theme.dim
                        text: "Clipboard"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ScreenshotState.copyToClipboard = !ScreenshotState.copyToClipboard
                }
            }

            // Save Toggle
            Rectangle {
                height: 32
                implicitWidth: saveRow.implicitWidth + 18
                radius: 16
                color: ScreenshotState.saveToDisk ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Theme.chipBg
                border.color: ScreenshotState.saveToDisk ? Theme.accent : Theme.cardBorder
                border.width: 1

                RowLayout {
                    id: saveRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 15
                        color: ScreenshotState.saveToDisk ? Theme.accent : Theme.dim
                        text: "save"
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: ScreenshotState.saveToDisk ? Theme.text : Theme.dim
                        text: "Save"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ScreenshotState.saveToDisk = !ScreenshotState.saveToDisk
                }
            }

            // Annotate Toggle
            Rectangle {
                height: 32
                implicitWidth: annRow.implicitWidth + 18
                radius: 16
                color: ScreenshotState.annotateAfter ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Theme.chipBg
                border.color: ScreenshotState.annotateAfter ? Theme.accent : Theme.cardBorder
                border.width: 1

                RowLayout {
                    id: annRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 15
                        color: ScreenshotState.annotateAfter ? Theme.accent : Theme.dim
                        text: "edit"
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: ScreenshotState.annotateAfter ? Theme.text : Theme.dim
                        text: "Annotate"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ScreenshotState.annotateAfter = !ScreenshotState.annotateAfter
                }
            }

            // Delay Selector
            Rectangle {
                height: 32
                implicitWidth: timerRow.implicitWidth + 16
                radius: 16
                color: ScreenshotState.delaySeconds > 0 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Theme.chipBg
                border.color: ScreenshotState.delaySeconds > 0 ? Theme.accent : Theme.cardBorder
                border.width: 1

                RowLayout {
                    id: timerRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                        color: ScreenshotState.delaySeconds > 0 ? Theme.accent : Theme.dim
                        text: "timer"
                    }

                    Text {
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: ScreenshotState.delaySeconds > 0 ? Theme.text : Theme.dim
                        text: ScreenshotState.delaySeconds === 0 ? "0s" : (ScreenshotState.delaySeconds + "s")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (ScreenshotState.delaySeconds === 0)
                            ScreenshotState.delaySeconds = 3;
                        else if (ScreenshotState.delaySeconds === 3)
                            ScreenshotState.delaySeconds = 5;
                        else
                            ScreenshotState.delaySeconds = 0;
                    }
                }
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 22
            color: Theme.glassBorder
            Layout.leftMargin: 4
            Layout.rightMargin: 4
        }

        // ==========================================
        // 3. CAPTURE & CLOSE ACTIONS
        // ==========================================
        RowLayout {
            spacing: 6

            // Primary Capture Button
            Rectangle {
                height: 34
                implicitWidth: captureRow.implicitWidth + 20
                radius: 17
                color: Theme.accent
                visible: ScreenshotState.mode === "fullscreen" || (ScreenshotState.mode === "region" && ScreenshotState.hasSelection)

                RowLayout {
                    id: captureRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 16
                        color: "#060605"
                        text: "photo_camera"
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: "#060605"
                        text: "Capture"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (ScreenshotState.mode === "fullscreen")
                            ScreenshotState.captureFullscreen();
                        else if (ScreenshotState.mode === "region") {
                            if (ScreenshotState.hasSelection)
                                ScreenshotState.captureSelection();
                            else
                                ScreenshotState.captureFullscreen();
                        } else if (ScreenshotState.mode === "window" && ScreenshotState.hoveredWindow) {
                            ScreenshotState.captureWindow(ScreenshotState.hoveredWindow);
                        }
                    }
                }
            }

            // Close (Cancel) Button
            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: closeMouse.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.20) : "transparent"

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 18
                    color: closeMouse.containsMouse ? Theme.error : Theme.dim
                    text: "close"
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ScreenshotState.cancel()
                }
            }
        }
    }
}
