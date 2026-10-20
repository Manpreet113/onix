import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.components
import qs.services
import qs.theme

// Caelestia / Apple Music Studio-Grade Ultra-Luxury Music Pop-up
Rectangle {
    id: root
    width: 380
    implicitHeight: mainCol.implicitHeight + 32
    height: implicitHeight

    property bool embedded: false

    color: embedded ? "transparent" : Theme.glassBg
    border.color: embedded ? "transparent" : Theme.glassBorder
    border.width: embedded ? 0 : 1
    radius: embedded ? 0 : 24
    clip: true

    // Top specular glass highlight line
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        height: 1
        color: Theme.glassSpecular
        visible: !root.embedded
    }

    // Deep ambient drop shadow
    Rectangle {
        z: -1
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: -4
        radius: parent.radius + 2
        color: Theme.glassShadow
        opacity: 0.65
        visible: !root.embedded
    }

    // Local player selector expansion state
    property bool playerMenuOpen: false

    // Local scrubber drag state (eliminates all DBus contention & progress jumping!)
    property bool isDragging: false
    property real dragProgress: 0.0
    readonly property real effectiveProgress: isDragging ? dragProgress : Media.progress
    readonly property real effectivePosition: isDragging ? (dragProgress * Media.trackLength) : Media.position

    // Countdown toggle
    property bool showRemainingTime: false

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 18
        spacing: 14

        // 1. Top Source & Status Header Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Player Identity Selector Pill
            Rectangle {
                radius: 8
                color: playerSelectMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                border.color: root.playerMenuOpen ? Theme.accent : Theme.cardBorder
                border.width: 1
                implicitHeight: 26
                implicitWidth: playerRow.implicitWidth + 14

                Behavior on color { ColorAnimation { duration: Motion.snappy } }
                Behavior on border.color { ColorAnimation { duration: Motion.snappy } }

                RowLayout {
                    id: playerRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 13
                        color: Theme.accent
                        text: "music_note"
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.text
                        text: Media.playerIdentity
                        elide: Text.ElideRight
                        Layout.maximumWidth: 130
                    }

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                        color: Theme.dim
                        text: root.playerMenuOpen ? "expand_less" : "expand_more"
                        visible: Media.availablePlayers.length > 1
                    }
                }

                MouseArea {
                    id: playerSelectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Media.availablePlayers.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (Media.availablePlayers.length > 1) {
                            root.playerMenuOpen = !root.playerMenuOpen;
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Live Animated Dancing Visualizer Pill
            Rectangle {
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.05)
                border.color: Qt.rgba(1, 1, 1, 0.07)
                border.width: 1
                implicitHeight: 26
                implicitWidth: visualizerRow.implicitWidth + 14

                RowLayout {
                    id: visualizerRow
                    anchors.centerIn: parent
                    spacing: 6

                    // Visualizer bars
                    Row {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 12

                        property real wave: 0
                        NumberAnimation on wave {
                            from: 0
                            to: 6.28
                            duration: 1100
                            loops: Animation.Infinite
                            running: Media.isPlaying
                        }

                        Rectangle {
                            width: 2.5
                            height: Media.isPlaying ? Math.max(3, 3 + 8 * Math.abs(Math.sin(visualizerRow.children[0].wave))) : 3
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 1.25
                            color: Theme.accent
                        }
                        Rectangle {
                            width: 2.5
                            height: Media.isPlaying ? Math.max(3, 3 + 10 * Math.abs(Math.sin(visualizerRow.children[0].wave + 1.2))) : 3
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 1.25
                            color: Theme.accent
                        }
                        Rectangle {
                            width: 2.5
                            height: Media.isPlaying ? Math.max(3, 3 + 7 * Math.abs(Math.sin(visualizerRow.children[0].wave + 2.4))) : 3
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 1.25
                            color: Theme.accent
                        }
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: Media.isPlaying ? Theme.accent : Theme.dim
                        text: Media.isPlaying ? "PLAYING" : "PAUSED"
                    }
                }
            }
        }

        // 1.5 Optional Player Selector Dropdown Drawer
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.playerMenuOpen && Media.availablePlayers.length > 1

            Repeater {
                model: Media.availablePlayers
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: 6
                    color: (Media.activePlayer === modelData) ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : (pItemMouse.containsMouse ? Theme.chipHover : Theme.cardBg)
                    border.color: (Media.activePlayer === modelData) ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.40) : Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 13
                            color: (Media.activePlayer === modelData) ? Theme.accent : Theme.dim
                            text: (modelData.playbackState === MprisPlaybackState.Playing) ? "volume_up" : "pause"
                        }

                        Text {
                            font.family: Theme.fontPrimary
                            font.pixelSize: 11
                            font.weight: (Media.activePlayer === modelData) ? Font.Bold : Font.Normal
                            color: Theme.text
                            text: modelData.identity || "Player"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            font.family: Theme.fontIcons
                            font.pixelSize: 14
                            color: Theme.accent
                            text: "check"
                            visible: Media.activePlayer === modelData
                        }
                    }

                    MouseArea {
                        id: pItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Media.selectPlayer(modelData);
                            root.playerMenuOpen = false;
                        }
                    }
                }
            }
        }

        // 2. Ultra-Luxury Squircle Artwork Centerpiece with Ambient Aura Glow
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 164
            Layout.preferredHeight: 164

            // Pulsing Ambient Aura Glow behind the album art
            Rectangle {
                anchors.centerIn: parent
                width: 172
                height: 172
                radius: 32
                color: Theme.accent
                opacity: Media.isPlaying ? 0.38 : 0.15
                Behavior on opacity { NumberAnimation { duration: 800 } }

                // Slow subtle breathing pulse when playing
                SequentialAnimation on scale {
                    running: Media.isPlaying
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.05; duration: 2400; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.00; duration: 2400; easing.type: Easing.InOutQuad }
                }
            }

            // Fallback artwork container (when image is absent or loading)
            Rectangle {
                id: fallbackContainer
                anchors.fill: parent
                radius: 22
                color: Theme.surfaceVariant
                border.color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 1
                visible: artImage.status !== Image.Ready

                Rectangle {
                    anchors.centerIn: parent
                    width: 72
                    height: 72
                    radius: 36
                    color: Qt.rgba(1, 1, 1, 0.05)

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontIcons
                        font.pixelSize: 36
                        color: Theme.accent
                        text: "graphic_eq"
                    }
                }
            }

            // Mask source item for pristine squircle clipping (ZERO corner bleed!)
            Item {
                id: artMask
                anchors.fill: parent
                visible: false
                layer.enabled: true
                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    color: "white"
                }
            }

            // Main Artwork Layer Container
            Item {
                id: artContainer
                anchors.fill: parent
                visible: artImage.status === Image.Ready
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: artMask
                }

                Image {
                    id: artImage
                    anchors.fill: parent
                    source: Media.trackArtUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }
            }

            // Inner Specular Glass Rim Line
            Rectangle {
                anchors.fill: parent
                radius: 22
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.18)
                border.width: 1
                z: 2
            }
        }

        // 3. Track Metadata (Title, Artist, Album)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 2

            Text {
                font.family: Theme.fontDisplay
                font.pixelSize: 18
                font.weight: Font.ExtraBold
                color: Theme.text
                text: Media.trackTitle || "No Track Active"
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Text {
                font.family: Theme.fontPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.accent
                text: Media.trackArtist || "Unknown Artist"
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Text {
                font.family: Theme.fontPrimary
                font.pixelSize: 11
                color: Theme.dim
                text: Media.trackAlbum || ""
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                visible: text.length > 0
                Layout.fillWidth: true
            }
        }

        // 4. Studio-Grade Precision Glass Scrubber
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Item {
                id: scrubArea
                Layout.fillWidth: true
                Layout.preferredHeight: 24

                // Floating live time tooltip bubble while scrubbing or hovering
                Rectangle {
                    id: scrubTooltip
                    anchors.bottom: trackBg.top
                    anchors.bottomMargin: 8
                    anchors.horizontalCenter: scrubKnob.horizontalCenter
                    implicitWidth: tooltipText.implicitWidth + 12
                    implicitHeight: 20
                    radius: 5
                    color: "#18181b"
                    border.color: Theme.accent
                    border.width: 1
                    opacity: (scrubMouse.containsMouse || root.isDragging) && (Media.trackLength > 0) ? 1.0 : 0.0
                    visible: opacity > 0.01

                    Behavior on opacity { NumberAnimation { duration: Motion.snappy } }

                    Text {
                        id: tooltipText
                        anchors.centerIn: parent
                        font.family: Theme.fontPrimary
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#ffffff"
                        text: Media.formatTime(root.effectivePosition)
                    }
                }

                // Background track bar (smooth expansion on hover/drag)
                Rectangle {
                    id: trackBg
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: (scrubMouse.containsMouse || root.isDragging) ? 6 : 4
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.12)

                    Behavior on height {
                        SpringAnimation {
                            spring: 3.5
                            damping: 0.65
                        }
                    }
                }

                // Active progress fill
                Rectangle {
                    id: trackFill
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: trackBg.height
                    radius: trackBg.radius
                    width: Math.max(0, Math.min(scrubArea.width, scrubArea.width * root.effectiveProgress))
                    color: Theme.accent
                }

                // Glowing Scrub Handle Knob
                Rectangle {
                    id: scrubKnob
                    anchors.horizontalCenter: trackFill.right
                    anchors.verticalCenter: scrubArea.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: "#ffffff"
                    border.color: Theme.accent
                    border.width: 2.5
                    visible: Media.trackLength > 0

                    scale: (scrubMouse.containsMouse || root.isDragging) ? 1.0 : 0.0
                    Behavior on scale {
                        SpringAnimation {
                            spring: 3.5
                            damping: 0.65
                        }
                    }

                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: parent.radius + 3
                        color: Theme.accent
                        opacity: 0.50
                    }
                }

                // Zero-latency local drag mouse area (strictly commits ON RELEASE!)
                MouseArea {
                    id: scrubMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onPressed: mouse => {
                        if (Media.trackLength <= 0) return;
                        root.isDragging = true;
                        root.dragProgress = Math.max(0.0, Math.min(1.0, mouse.x / scrubArea.width));
                    }

                    onPositionChanged: mouse => {
                        if (pressed && Media.trackLength > 0) {
                            root.dragProgress = Math.max(0.0, Math.min(1.0, mouse.x / scrubArea.width));
                        }
                    }

                    onReleased: mouse => {
                        if (root.isDragging && Media.trackLength > 0) {
                            const target = root.dragProgress * Media.trackLength;
                            Media.seek(target);
                            root.isDragging = false;
                        }
                    }

                    onCanceled: {
                        root.isDragging = false;
                    }
                }
            }

            // Timers Row (Elapsed vs Remaining/Total with interactive toggle)
            RowLayout {
                Layout.fillWidth: true

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.dim
                    text: Media.formatTime(root.effectivePosition)
                }

                Item { Layout.fillWidth: true }

                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Theme.dim
                    text: root.showRemainingTime
                          ? ("-" + Media.formatTime(Math.max(0.0, Media.trackLength - root.effectivePosition)))
                          : Media.formatTime(Media.trackLength)

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showRemainingTime = !root.showRemainingTime
                    }
                }
            }
        }

        // 5. Deluxe Balanced Transport Bar (Shuffle • -10s • Prev • Play • Next • +10s • Loop)
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            // Shuffle Button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: shuffleMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                border.color: Media.isShuffle ? Theme.accent : Theme.cardBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: Motion.snappy } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 16
                    color: Media.isShuffle ? Theme.accent : Theme.subtext
                    text: "shuffle"
                }

                // Indicator dot when active
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 4
                    height: 4
                    radius: 2
                    color: Theme.accent
                    visible: Media.isShuffle
                }

                MouseArea {
                    id: shuffleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.toggleShuffle()
                }
            }

            // Skip -10s
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: skipBackMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                border.color: Theme.cardBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: Motion.snappy } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 17
                    color: Theme.subtext
                    text: "replay_10"
                }

                MouseArea {
                    id: skipBackMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.seekRelative(-10)
                }
            }

            // Previous Track
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: prevMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                border.color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Theme.cardBorder
                border.width: 1
                scale: prevMouse.pressed ? 0.92 : 1.0
                Behavior on scale { SpringAnimation { spring: 4; damping: 0.6 } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 22
                    color: Theme.text
                    text: "skip_previous"
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.previous()
                }
            }

            // Hero Play / Pause Floating Action Button (54px)
            Rectangle {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 54
                radius: 27
                color: Theme.accent
                scale: playHeroMouse.pressed ? 0.90 : (playHeroMouse.containsMouse ? 1.06 : 1.0)
                Behavior on scale { SpringAnimation { spring: 3.5; damping: 0.6 } }

                // Ambient glow around play button
                Rectangle {
                    z: -1
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: parent.radius + 4
                    color: Theme.accent
                    opacity: playHeroMouse.containsMouse ? 0.45 : 0.25
                    Behavior on opacity { NumberAnimation { duration: Motion.snappy } }
                }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 30
                    color: "#08080a"
                    text: Media.isPlaying ? "pause" : "play_arrow"
                }

                MouseArea {
                    id: playHeroMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.togglePlay()
                }
            }

            // Next Track
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: nextMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                border.color: nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Theme.cardBorder
                border.width: 1
                scale: nextMouse.pressed ? 0.92 : 1.0
                Behavior on scale { SpringAnimation { spring: 4; damping: 0.6 } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 22
                    color: Theme.text
                    text: "skip_next"
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.next()
                }
            }

            // Forward +10s
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: skipFwdMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                border.color: Theme.cardBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: Motion.snappy } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 17
                    color: Theme.subtext
                    text: "forward_10"
                }

                MouseArea {
                    id: skipFwdMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.seekRelative(10)
                }
            }

            // Repeat / Loop Button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: loopMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                border.color: (Media.loopState !== MprisLoopState.None) ? Theme.accent : Theme.cardBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: Motion.snappy } }

                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontIcons
                    font.pixelSize: 16
                    color: (Media.loopState !== MprisLoopState.None) ? Theme.accent : Theme.subtext
                    text: (Media.loopState === MprisLoopState.Track) ? "repeat_one" : "repeat"
                }

                // Indicator dot when active
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 4
                    height: 4
                    radius: 2
                    color: Theme.accent
                    visible: Media.loopState !== MprisLoopState.None
                }

                MouseArea {
                    id: loopMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.cycleLoop()
                }
            }
        }

        // 6. Integrated Glass Volume Controller Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 10
            color: Theme.cardBg
            border.color: Theme.cardBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                // Speaker Icon (clickable to toggle mute)
                Text {
                    font.family: Theme.fontIcons
                    font.pixelSize: 17
                    color: Media.volume > 0 ? Theme.subtext : Theme.dim
                    text: {
                        if (Media.volume <= 0.01) return "volume_mute";
                        if (Media.volume < 0.50) return "volume_down";
                        return "volume_up";
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Media.volume > 0.01) Media.setVolume(0.0);
                            else Media.setVolume(0.8);
                        }
                    }
                }

                // Volume Slider Track
                Item {
                    id: volArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16

                    Rectangle {
                        id: volBg
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: volMouse.containsMouse ? 6 : 4
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.12)

                        Behavior on height {
                            SpringAnimation {
                                spring: 3.5
                                damping: 0.65
                            }
                        }
                    }

                    Rectangle {
                        id: volFill
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        height: volBg.height
                        radius: volBg.radius
                        width: Math.max(0, Math.min(volArea.width, volArea.width * Media.volume))
                        color: Theme.accent
                    }

                    Rectangle {
                        anchors.horizontalCenter: volFill.right
                        anchors.verticalCenter: volArea.verticalCenter
                        width: 12
                        height: 12
                        radius: 6
                        color: "#ffffff"
                        border.color: Theme.accent
                        border.width: 2
                        scale: volMouse.containsMouse ? 1.0 : 0.0
                        Behavior on scale { SpringAnimation { spring: 3.5; damping: 0.65 } }
                    }

                    MouseArea {
                        id: volMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        function updateVol(mouseX): void {
                            const v = Math.max(0.0, Math.min(1.0, mouseX / volArea.width));
                            Media.setVolume(v);
                        }

                        onClicked: mouse => updateVol(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed) updateVol(mouse.x);
                        }
                    }
                }

                // Percentage text
                Text {
                    font.family: Theme.fontPrimary
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: Theme.dim
                    text: `${Math.round(Media.volume * 100)}%`
                    Layout.preferredWidth: 28
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
