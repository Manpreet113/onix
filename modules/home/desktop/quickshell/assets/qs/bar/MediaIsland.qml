import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import qs.components
import qs.popups
import qs.services
import qs.theme

// Dedicated Dynamic Media Island: Only appears when media is playing
Rectangle {
    id: root

    readonly property bool isPlaying: Media.isPlaying
    readonly property bool hasMedia: Media.hasMedia && (isPlaying || pauseGraceTimer.running)
    readonly property bool isExpanded: PopupState.activePopup === "media"
    readonly property bool shouldBeVisible: hasMedia || isExpanded

    Timer {
        id: pauseGraceTimer
        interval: 8000
        repeat: false
    }

    Connections {
        target: root
        function onIsPlayingChanged() {
            if (!root.isPlaying && Media.hasMedia) {
                pauseGraceTimer.restart();
            } else if (root.isPlaying) {
                pauseGraceTimer.stop();
            }
        }
    }

    readonly property int targetWidth: {
        if (isExpanded) return 380;
        if (!shouldBeVisible) return 0;
        return mediaCollapsedRow.implicitWidth + 24;
    }

    readonly property int targetHeight: {
        if (isExpanded) return Math.min(540, mediaView.implicitHeight + 46);
        return 40;
    }

    width: targetWidth
    height: targetHeight
    radius: isExpanded ? 24 : 20
    visible: opacity > 0.01
    opacity: shouldBeVisible ? 1.0 : 0.0
    clip: true

    color: isExpanded ? Theme.glassBg : (islandMouse.containsMouse ? Qt.rgba(Theme.glassBg.r * 1.15, Theme.glassBg.g * 1.15, Theme.glassBg.b * 1.15, 0.90) : Theme.glassBg)
    border.color: isExpanded ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.40) : (islandMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Theme.glassBorder)
    border.width: 1

    Behavior on width {
        SpringAnimation {
            spring: Motion.springStiffness
            damping: Motion.springDamping
        }
    }
    Behavior on height {
        SpringAnimation {
            spring: Motion.springStiffness
            damping: Motion.springDamping
        }
    }
    Behavior on radius { NumberAnimation { duration: Motion.effects } }
    Behavior on opacity { NumberAnimation { duration: Motion.effects } }
    Behavior on color { ColorAnimation { duration: Motion.effects } }
    Behavior on border.color { ColorAnimation { duration: Motion.effects } }

    // Ambient Drop Shadow
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        anchors.bottomMargin: -3
        radius: parent.radius + 2
        color: Theme.glassShadow
        opacity: root.isExpanded ? 0.75 : (root.shouldBeVisible ? 0.50 : 0.0)
        Behavior on opacity { NumberAnimation { duration: Motion.effects } }
    }

    // Top Specular Highlight Line
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: 1
        color: Theme.glassSpecular
        visible: root.width > 30
    }

    // Collapsed Viewport (Interactive music chip)
    Item {
        id: collapsedView
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        visible: opacity > 0.01
        opacity: root.isExpanded ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: Motion.effects } }

        MouseArea {
            id: islandMouse
            anchors.fill: parent
            enabled: !root.isExpanded
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: PopupState.toggle("media")
        }

        RowLayout {
            id: mediaCollapsedRow
            anchors.centerIn: parent
            spacing: 8

            // Waveform Animation Value
            property real waveVal: 0
            NumberAnimation on waveVal {
                from: 0
                to: 6.28
                duration: 1100
                loops: Animation.Infinite
                running: root.isPlaying
            }

            // Music Note / Album Art Thumbnail (MultiEffect squircle - zero bleed!)
            Item {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26

                Item {
                    id: thumbMask
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true
                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        color: "white"
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color: Theme.chipBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                        color: Theme.accent
                        text: "music_note"
                        visible: thumbImg.status !== Image.Ready
                    }
                }

                Item {
                    anchors.fill: parent
                    visible: thumbImg.status === Image.Ready
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: thumbMask
                    }

                    Image {
                        id: thumbImg
                        anchors.fill: parent
                        source: Media.trackArtUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                    }
                }
            }

            // Track Title
            Text {
                font.family: Theme.fontPrimary
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Theme.text
                elide: Text.ElideRight
                Layout.maximumWidth: 140
                text: (Media.trackTitle || "Track") + (Media.trackArtist ? " • " + Media.trackArtist : "")
            }

            // Animated Mini Equalizer Bars (4 harmonic bars)
            Row {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 14

                Rectangle {
                    width: 2.5
                    height: root.isPlaying ? Math.max(3, 3 + 8 * Math.abs(Math.sin(mediaCollapsedRow.waveVal))) : 3
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 1.25
                    color: Theme.accent
                }
                Rectangle {
                    width: 2.5
                    height: root.isPlaying ? Math.max(3, 3 + 10 * Math.abs(Math.sin(mediaCollapsedRow.waveVal + 0.9))) : 3
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 1.25
                    color: Theme.accent
                }
                Rectangle {
                    width: 2.5
                    height: root.isPlaying ? Math.max(3, 3 + 7 * Math.abs(Math.sin(mediaCollapsedRow.waveVal + 1.8))) : 3
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 1.25
                    color: Theme.accent
                }
                Rectangle {
                    width: 2.5
                    height: root.isPlaying ? Math.max(3, 3 + 9 * Math.abs(Math.sin(mediaCollapsedRow.waveVal + 2.7))) : 3
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 1.25
                    color: Theme.accent
                }
            }

            // Play / Pause mini button
            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: playMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                border.color: Theme.cardBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: Motion.snappy } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 14
                    color: Theme.text
                    text: root.isPlaying ? "pause" : "play_arrow"
                }

                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.togglePlay()
                }
            }
        }
    }

    // Expanded Viewport Header (height: 40)
    Item {
        id: expandedHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40

        // Close chip when expanded
        GlassChip {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: opacity > 0.01
            opacity: root.isExpanded ? 1.0 : 0.0
            implicitWidth: 28
            implicitHeight: 28
            squircleRadius: 13
            bg: Qt.rgba(1, 1, 1, 0.08)
            hoverBg: Qt.rgba(1, 1, 1, 0.20)
            fg: Theme.text

            Behavior on opacity { NumberAnimation { duration: Motion.effects } }

            Text {
                Layout.alignment: Qt.AlignCenter
                font.family: Theme.fontIcons
                font.pixelSize: 15
                color: Theme.text
                text: "close"
            }

            onClicked: PopupState.close()
        }
    }

    // Specular Divider below header
    Rectangle {
        anchors.top: expandedHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: 1
        color: Theme.glassSpecular
        visible: opacity > 0.01
        opacity: root.isExpanded ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Motion.effects } }
    }

    // Expanded Body (Hosts MediaPopup)
    Flickable {
        id: mediaBody
        anchors.top: expandedHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        visible: root.height > 60
        contentWidth: width
        contentHeight: mediaView.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        MediaPopup {
            id: mediaView
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            embedded: true
            visible: opacity > 0.01
            opacity: root.isExpanded ? 1.0 : 0.0
            transform: Translate {
                y: root.isExpanded ? 0 : 8
                Behavior on y { NumberAnimation { duration: Motion.effects; easing.type: Easing.OutCubic } }
            }
            Behavior on opacity { NumberAnimation { duration: Motion.effects } }
        }
    }
}
