// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixSettingsWin: settings window (ports upstream Settings). Header with
// breadcrumb, navigation rail, reload control, and the seven tabs. Toggle
// with `ipc call onixSettings toggle`.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    visible: OnixUi.settingsOpen
    focusable: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    color: Qt.rgba(OnixTheme.mScrim.r, OnixTheme.mScrim.g, OnixTheme.mScrim.b, 0.6)

    property string tab: "quick"
    readonly property var tabs: [
        { key: "quick", icon: "bolt", label: "Quick" },
        { key: "appearance", icon: "palette", label: "Appearance" },
        { key: "interface", icon: "tune", label: "Interface" },
        { key: "services", icon: "api", label: "Services" },
        { key: "network", icon: "network_wifi", label: "Network" },
        { key: "bluetooth", icon: "bluetooth", label: "Bluetooth" },
        { key: "about", icon: "info", label: "System" }
    ]

    function tabLabel(): string {
        for (var i = 0; i < root.tabs.length; i++) {
            if (root.tabs[i].key === root.tab)
                return root.tabs[i].label;
        }
        return "";
    }

    function close(): void {
        OnixUi.settingsOpen = false;
    }

    Keys.onEscapePressed: root.close()

    IpcHandler {
        target: "onixSettings"
        function toggle(): void {
            OnixUi.toggleSettings();
        }
        function open(): void {
            OnixUi.settingsOpen = true;
        }
        function close(): void {
            root.close();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        implicitWidth: Math.min(1200, parent.width - 80)
        implicitHeight: Math.min(900, parent.height - 80)
        color: OnixTheme.mSurfaceContainerLow
        radius: 20
        border.color: OnixTheme.mOutlineVariant
        border.width: 1

        Column {
            anchors.fill: parent
            spacing: 0

            // header bar with breadcrumb
            Row {
                width: parent.width
                height: 56
                spacing: 8
                leftPadding: 16
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "settings"
                    color: OnixTheme.mOnSurface
                    font.family: OnixTheme.iconFont
                    font.pixelSize: 24
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Onix Settings"
                    color: OnixTheme.mOnSurface
                    font.pixelSize: OnixTheme.fontLarge
                    font.bold: true
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ">"
                    color: OnixTheme.mOnSurfaceVariant
                    font.pixelSize: OnixTheme.fontLarge
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.tabLabel()
                    color: OnixTheme.mOnSurfaceVariant
                    font.pixelSize: OnixTheme.fontLarge
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: OnixTheme.mOutlineVariant
            }

            Row {
                width: parent.width
                height: parent.height - 57

                Column {
                    width: 120
                    height: parent.height
                    spacing: 0

                    M3NavRail {
                        items: root.tabs
                        current: {
                            for (var i = 0; i < root.tabs.length; i++) {
                                if (root.tabs[i].key === root.tab)
                                    return i;
                            }
                            return 0;
                        }
                        onSelected: index => {
                            root.tab = root.tabs[index].key;
                        }
                    }

                    Item {
                        width: 1
                        height: 10
                    }

                    M3Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        btnType: "tonal"
                        size: "s"
                        shape: "square"
                        icon: "restart_alt"
                        onClicked: Quickshell.execDetached(["systemctl", "--user", "restart", "quickshell.service"])
                    }
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color: OnixTheme.mOutlineVariant
                }

                Flickable {
                    width: parent.width - 121
                    height: parent.height
                    contentWidth: width
                    contentHeight: tabLoader.implicitHeight + 32
                    clip: true

                    Loader {
                        id: tabLoader
                        anchors {
                            top: parent.top
                            horizontalCenter: parent.horizontalCenter
                            margins: 16
                        }
                        width: 800
                        sourceComponent: root.compFor(root.tab)
                    }
                }
            }
        }
    }

    Component {
        id: tabQuick
        OnixTabQuick {
        }
    }
    Component {
        id: tabAppearance
        OnixTabAppearance {
        }
    }
    Component {
        id: tabInterface
        OnixTabInterface {
        }
    }
    Component {
        id: tabServices
        OnixTabServices {
        }
    }
    Component {
        id: tabNetwork
        OnixTabNetwork {
        }
    }
    Component {
        id: tabBluetooth
        OnixTabBluetooth {
        }
    }
    Component {
        id: tabAbout
        OnixTabAbout {
        }
    }

    function compFor(key): Component {
        switch (key) {
        case "appearance":
            return tabAppearance;
        case "interface":
            return tabInterface;
        case "services":
            return tabServices;
        case "network":
            return tabNetwork;
        case "bluetooth":
            return tabBluetooth;
        case "about":
            return tabAbout;
        default:
            return tabQuick;
        }
    }
}
