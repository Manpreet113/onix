// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixNotifs: notification popups (ports upstream notifications.py +
// popup.py). Cards carry icon / summary / relative age / expandable body /
// action buttons / close; compact mode collapses to a single line.
// Position + compactness come from OnixSettings; newest-first when the bar
// sits on top, like upstream. History lives in the quickcenter (P4).
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    readonly property var anchorNames: OnixSettings.get(["interface", "notifications", "anchor"], ["top", "right"])
    readonly property bool compact: OnixSettings.get(["interface", "notifications", "compact_popup"], false)
    readonly property bool newestFirst: OnixSettings.get(["interface", "bar", "side"], "bottom") === "top"

    anchors {
        top: root.anchorNames.indexOf("top") >= 0
        bottom: root.anchorNames.indexOf("bottom") >= 0
        left: root.anchorNames.indexOf("left") >= 0
        right: root.anchorNames.indexOf("right") >= 0
    }
    margins {
        top: 12
        bottom: 12
        left: 12
        right: 12
    }
    implicitWidth: 360
    implicitHeight: list.implicitHeight
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: server.trackedNotifications.length > 0 || root.closing > 0

    property int closing: 0

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        actionsSupported: true
        onNotification: notification => {
            notification.tracked = true;
        }
    }

    function relativeTime(ts) {
        var diff = Math.floor(Date.now() / 1000 - ts);
        if (diff < 60)
            return "now";
        if (diff < 3600)
            return Math.floor(diff / 60) + "m";
        if (diff < 86400)
            return Math.floor(diff / 3600) + "h";
        return Math.floor(diff / 86400) + "d";
    }

    Column {
        id: list
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 6

        Repeater {
            model: root.newestFirst ? [...server.trackedNotifications].reverse() : server.trackedNotifications
            delegate: Rectangle {
                id: card
                required property var modelData

                property bool expanded: false
                property bool dismissed: false
                property bool shown: false
                property double born: (modelData.time !== undefined && modelData.time > 0) ? modelData.time : Date.now() / 1000
                property string ageText: root.relativeTime(card.born)

                implicitWidth: 360
                implicitHeight: inner.implicitHeight + 24
                color: OnixTheme.mSurfaceContainer
                radius: OnixTheme.radiusLarge
                border.color: OnixTheme.mOutlineVariant
                border.width: 1

                y: shown ? 0 : -12
                opacity: (shown && !dismissed) ? 1 : 0
                Behavior on y {
                    NumberAnimation {
                        duration: OnixTheme.fadeMed
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: OnixTheme.fadeFast
                    }
                }
                Component.onCompleted: card.shown = true

                function dismiss(): void {
                    if (card.dismissed)
                        return;
                    card.dismissed = true;
                    root.closing++;
                    closeTimer.restart();
                }

                Timer {
                    id: closeTimer
                    interval: OnixTheme.fadeFast + 30
                    repeat: false
                    onTriggered: {
                        root.closing--;
                        card.modelData.expire();
                    }
                }

                Timer {
                    id: ageTimer
                    interval: 60000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: card.ageText = root.relativeTime(card.born)
                }

                Timer {
                    interval: modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000
                    running: true
                    repeat: false
                    onTriggered: card.dismiss()
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
                            visible: (modelData.appIcon || "") !== ""
                            source: Quickshell.iconPath(modelData.appIcon || "", "")
                        }
                    }

                    Column {
                        width: inner.width - 38 - btnCol.width - 20
                        spacing: root.compact ? 8 : 2

                        Row {
                            spacing: 5
                            Text {
                                text: modelData.summary || ""
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
                                    text: card.ageText
                                    color: OnixTheme.mOnSurfaceVariant
                                    font.pixelSize: OnixTheme.fontSmall
                                }
                            }
                        }

                        Text {
                            visible: (modelData.body || "") !== ""
                            text: modelData.body || ""
                            color: OnixTheme.mOnSurfaceVariant
                            font.pixelSize: OnixTheme.fontSmall
                            wrapMode: card.expanded ? Text.WordWrap : Text.NoWrap
                            elide: card.expanded ? Text.ElideNone : Text.ElideRight
                            maximumLineCount: (card.expanded || root.compact) ? 1 : 3
                            width: parent.width
                            textFormat: Text.RichText
                        }

                        Row {
                            visible: !root.compact && modelData.actions && modelData.actions.length > 0
                            spacing: 4
                            Repeater {
                                model: card.modelData.actions
                                delegate: M3Button {
                                    required property var modelData
                                    btnType: "text"
                                    size: "xs"
                                    label: modelData.text || ""
                                    onClicked: modelData.invoke()
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
                            onClicked: card.dismiss()
                        }
                        M3Button {
                            visible: !root.compact && (card.modelData.body || "") !== ""
                            btnType: "text"
                            size: "xs"
                            icon: card.expanded ? "arrow_drop_up" : "arrow_drop_down"
                            onClicked: card.expanded = !card.expanded
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: card.dismiss()
                }
            }
        }
    }
}
