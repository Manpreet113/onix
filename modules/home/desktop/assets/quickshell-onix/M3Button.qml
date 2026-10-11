// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// M3Button: Material-3 button (ports upstream NewButton + Button). Types:
// elevated / filled / tonal / outlined / text. Sizes xs / s / m / l / xl.
// Shape round (full pill, default) or square. `active` fills the button for
// connected-group selected state. Icon is a Material Symbols ligature;
// labels use the system default sans like upstream.
import QtQuick

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string btnType: "tonal"
    property string size: "s"
    property string shape: "round"
    property bool active: false

    signal clicked(var mouse)

    readonly property bool iconOnly: root.icon !== "" && root.label === ""
    readonly property int minH: ({ xs: 32, s: 40, m: 56, l: 96, xl: 136 })[root.size] ?? 40
    readonly property int hPad: {
        var pads = { xs: 12, s: 16, m: 24, l: 48, xl: 64 };
        var iconPads = { xs: 6, s: 10, m: 16, l: 32, xl: 48 };
        var base = pads[root.size] ?? 16;
        return root.iconOnly ? (iconPads[root.size] ?? 10) : base;
    }
    readonly property int iconPx: ({ xs: 20, s: 20, m: 24, l: 32, xl: 40 })[root.size] ?? 20
    readonly property int labelPx: ({ xs: 13, s: 13, m: 16, l: 22, xl: 30 })[root.size] ?? 13
    readonly property int squareR: ({ xs: 12, s: 12, m: 16, l: 28, xl: 28 })[root.size] ?? 12
    readonly property int pressedR: ({ xs: 8, s: 8, m: 12, l: 12, xl: 16 })[root.size] ?? 8
    readonly property int gap: (root.size === "l" || root.size === "xl") ? (root.size === "xl" ? 16 : 12) : 8

    readonly property color bg: {
        if (root.active && (root.btnType === "tonal" || root.btnType === "elevated"))
            return OnixTheme.mPrimary;
        switch (root.btnType) {
        case "elevated": return OnixTheme.mSurfaceContainer;
        case "filled": return OnixTheme.mPrimary;
        case "tonal": return OnixTheme.mSecondaryContainer;
        default: return "transparent";
        }
    }
    readonly property color fg: {
        if (root.active && (root.btnType === "tonal" || root.btnType === "elevated"))
            return OnixTheme.mOnPrimary;
        switch (root.btnType) {
        case "elevated": return OnixTheme.mPrimary;
        case "filled": return OnixTheme.mOnPrimary;
        case "tonal": return OnixTheme.mOnSecondaryContainer;
        case "outlined": return OnixTheme.mOnSurfaceVariant;
        default: return OnixTheme.mPrimary;
        }
    }

    implicitWidth: row.implicitWidth + root.hPad * 2
    implicitHeight: root.minH
    color: root.bg
    radius: root.shape === "round" ? OnixTheme.radiusFull : (mouse.pressed ? root.pressedR : root.squareR)
    border.color: root.btnType === "outlined" ? OnixTheme.mOutlineVariant : "transparent"
    border.width: root.btnType === "outlined" ? 1 : 0
    opacity: root.enabled ? 1 : 0.38

    Behavior on radius {
        NumberAnimation {
            duration: 60
        }
    }

    // M3 state layer: content color at 8% hover / 10% pressed
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.fg
        opacity: mouse.pressed ? 0.1 : (mouse.containsMouse ? 0.08 : 0)
        Behavior on opacity {
            NumberAnimation {
                duration: OnixTheme.fadeFast
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.gap

        Text {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.fg
            font.family: OnixTheme.iconFont
            font.pixelSize: root.iconPx
        }
        Text {
            visible: root.label !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.fg
            font.pixelSize: root.labelPx
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: root.enabled
        onClicked: mouse => root.clicked(mouse)
    }
}
