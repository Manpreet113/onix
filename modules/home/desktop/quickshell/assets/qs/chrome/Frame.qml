import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    property int radius: 20

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: false
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "onix-frame"

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "#000000"
        border.width: 2
        radius: root.radius
    }

    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            const r = root.radius;
            ctx.clearRect(0, 0, width, height);
            ctx.globalCompositeOperation = "source-over";
            ctx.fillStyle = "#000000";
            ctx.fillRect(0, 0, width, height);
            ctx.globalCompositeOperation = "destination-out";
            ctx.beginPath();
            ctx.moveTo(r, 0);
            ctx.lineTo(width - r, 0);
            ctx.arcTo(width, 0, width, r, r);
            ctx.lineTo(width, height - r);
            ctx.arcTo(width, height, width - r, height, r);
            ctx.lineTo(r, height);
            ctx.arcTo(0, height, 0, height - r, r);
            ctx.lineTo(0, r);
            ctx.arcTo(0, 0, r, 0, r);
            ctx.closePath();
            ctx.fill();
        }
    }
}
