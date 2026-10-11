// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixNotifs: notification popups (ports upstream popup.py). Slide-down
// cards via the shared OnixNotifCard; arrivals also snapshot into
// OnixNotifHistory for the quickcenter. Position + compactness come from
// OnixSettings; newest-first when the bar sits on top, like upstream.
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland

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
            OnixNotifHistory.push(notification.summary, notification.body, notification.appIcon, notification.appName);
        }
    }

    function clearPopups(): void {
        var vals = server.trackedNotifications;
        for (var i = 0; i < vals.length; i++)
            vals[i].expire();
    }

    Connections {
        target: OnixUi
        function onClearPopupsRequested() {
            root.clearPopups();
        }
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
            delegate: Item {
                required property var modelData

                property bool dismissed: false
                property bool shown: false

                implicitWidth: 360
                implicitHeight: card.implicitHeight

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
                Component.onCompleted: shown = true

                function dismiss(): void {
                    if (dismissed)
                        return;
                    dismissed = true;
                    root.closing++;
                    closeTimer.restart();
                }

                Timer {
                    id: closeTimer
                    interval: OnixTheme.fadeFast + 30
                    repeat: false
                    onTriggered: {
                        root.closing--;
                        modelData.expire();
                    }
                }

                Timer {
                    interval: modelData.expireTimeout > 0 ? modelData.expireTimeout * 1000 : 5000
                    running: true
                    repeat: false
                    onTriggered: dismiss()
                }

                OnixNotifCard {
                    id: card
                    summary: modelData.summary || ""
                    body: modelData.body || ""
                    iconName: modelData.appIcon || ""
                    born: Date.now() / 1000
                    compact: root.compact
                    actions: modelData.actions
                    onDismissed: dismiss()
                    onActionFired: action => {
                        try {
                            action.invoke();
                        } catch (e) {
                        }
                    }
                }
            }
        }
    }
}
