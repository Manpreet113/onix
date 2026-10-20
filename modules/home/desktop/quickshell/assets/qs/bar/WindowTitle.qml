import QtQuick
import QtQuick.Layouts
import qs.services
import qs.theme

// Caelestia Clean Window Title Chip
Rectangle {
    id: root
    implicitHeight: 28
    implicitWidth: Math.min(220, titleRow.implicitWidth + 18)
    radius: 14
    color: titleMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
    border.color: titleMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
    border.width: 1
    clip: true

    Behavior on color { ColorAnimation { duration: Motion.snappy } }
    Behavior on border.color { ColorAnimation { duration: Motion.snappy } }

    readonly property string rawTitle: (Hypr.activeToplevel?.title ?? "").trim()
    readonly property string appClass: (Hypr.activeToplevel?.wmClass ?? "").toLowerCase()
    readonly property bool isDesktop: rawTitle.length === 0
    readonly property string displayTitle: {
        if (!rawTitle) return "Desktop";
        return rawTitle.length > 24 ? rawTitle.slice(0, 23) + "…" : rawTitle;
    }

    readonly property string iconGlyph: {
        if (isDesktop)
            return "desktop_windows";
        if (appClass.includes("zen") || appClass.includes("firefox") || appClass.includes("chrome") || appClass.includes("browser"))
            return "language";
        if (appClass.includes("kitty") || appClass.includes("terminal") || appClass.includes("alacritty") || appClass.includes("foot"))
            return "terminal";
        if (appClass.includes("code") || appClass.includes("nvim") || appClass.includes("editor"))
            return "code";
        if (appClass.includes("spotify") || appClass.includes("music") || appClass.includes("audacious"))
            return "music_note";
        if (appClass.includes("discord") || appClass.includes("vesktop") || appClass.includes("telegram"))
            return "forum";
        return "desktop_windows";
    }

    visible: true
    opacity: 1

    Behavior on implicitWidth {
        SpringAnimation {
            spring: Motion.springStiffness
            damping: Motion.springDamping
        }
    }

    RowLayout {
        id: titleRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            font.family: Theme.fontIcons
            font.pixelSize: 13
            color: root.isDesktop ? Theme.dim : Theme.accent
            text: root.iconGlyph
            Behavior on color { ColorAnimation { duration: Motion.effects } }
        }

        Text {
            font.family: Theme.fontPrimary
            font.pixelSize: 11
            font.weight: root.isDesktop ? Font.Normal : Font.Medium
            color: root.isDesktop ? Theme.dim : Theme.text
            text: root.displayTitle
            elide: Text.ElideRight
            Layout.maximumWidth: 180
            Behavior on color { ColorAnimation { duration: Motion.effects } }
        }
    }

    MouseArea {
        id: titleMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.isDesktop ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: {
            if (Hypr.activeToplevel) Hypr.activeToplevel.focus();
        }
    }
}
