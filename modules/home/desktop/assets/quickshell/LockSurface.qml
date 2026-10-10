import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.UPower

// Per-screen lock UI. Auth state lives in Lock (context) so every
// screen shares one password entry; this is presentation + input.
Item {
    id: root

    required property var context

    property var player: {
        var vals = Mpris.players.values;
        for (var i = 0; i < vals.length; i++)
            if (vals[i].isPlaying)
                return vals[i];
        return vals.length > 0 ? vals[0] : null;
    }

    property string clock: Qt.formatDateTime(new Date(), "HH:mm")
    property string date: Qt.formatDateTime(new Date(), "dddd d MMM")
    property int battPct: {
        if (!UPower.displayDevice)
            return -1;
        var p = UPower.displayDevice.percentage;
        return p > 1 ? Math.round(p) : Math.round(p * 100);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.clock = Qt.formatDateTime(new Date(), "HH:mm");
            root.date = Qt.formatDateTime(new Date(), "dddd d MMM");
        }
    }

    // wallpaper backdrop, dimmed
    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }
    Image {
        anchors.fill: parent
        source: WallpaperState.current.length > 0 ? WallpaperState.fileUrl(WallpaperState.current) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }
    Rectangle {
        anchors.fill: parent
        color: Theme.backdrop
        opacity: 0.55
    }

    // clock + password, centered
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.clock
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 84
            font.bold: true
            renderType: Text.NativeRendering
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.date
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLarge
        }

        Item {
            width: 1
            height: 18
        }

        TextInput {
            id: passBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 260
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLarge
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData
            selectByMouse: false
            focus: true
            enabled: !root.context.unlockInProgress
            horizontalAlignment: Text.AlignHCenter
            onTextChanged: root.context.currentText = text
            onAccepted: root.context.tryUnlock()

            Rectangle {
                anchors.fill: parent
                anchors.margins: -10
                color: root.context.showFailure ? Theme.failure : Theme.surface
                radius: Theme.radiusMed
                border.color: root.context.showFailure ? Theme.error : Theme.border
                border.width: 1
                z: -1
            }

            Rectangle {
                visible: root.context.showFailure
                anchors.left: parent.left
                anchors.leftMargin: -10
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: parent.height + 6
                radius: 2
                color: Theme.error
            }

            Connections {
                target: root.context
                function onCurrentTextChanged() {
                    if (passBox.text !== root.context.currentText)
                        passBox.text = root.context.currentText;
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.context.unlockInProgress ? "checking…" : root.context.showFailure ? "incorrect password" : "enter password to unlock"
            color: root.context.showFailure ? Theme.error : Theme.dim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
        }
    }

    // media, bottom-left
    RowLayout {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 10
        visible: root.player !== null

        Text {
            text: root.player && root.player.isPlaying ? "⏸" : "▶"
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 22
            Layout.alignment: Qt.AlignVCenter
            MouseArea {
                anchors.fill: parent
                enabled: root.player && root.player.canTogglePlaying
                onClicked: root.player.isPlaying = !root.player.isPlaying
            }
        }
        Column {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            Text {
                text: (root.player && root.player.trackTitle) || "Unknown Title"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMed
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                text: (root.player && root.player.trackArtist) || (root.player && root.player.identity) || ""
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }
    }

    // battery, bottom-right
    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 8
        visible: UPower.displayDevice && UPower.displayDevice.isPresent && root.battPct >= 0

        Text {
            text: {
                if (!UPower.onBattery)
                    return "󰂄";
                var p = root.battPct;
                if (p >= 90)
                    return "󰁹";
                if (p >= 80)
                    return "󰂂";
                if (p >= 70)
                    return "󰂁";
                if (p >= 60)
                    return "󰂀";
                if (p >= 50)
                    return "󰁿";
                if (p >= 40)
                    return "󰁾";
                if (p >= 30)
                    return "󰁽";
                if (p >= 20)
                    return "󰁼";
                if (p >= 10)
                    return "󰁻";
                return "󰁺";
            }
            color: (root.battPct <= 15 && UPower.onBattery) ? Theme.error : Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: 20
        }
        Text {
            text: root.battPct + "%"
            color: Theme.subtext
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMed
        }
    }
}
