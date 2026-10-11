// Ported from Exo by debuggyo (GPL-3.0) — see LICENSE and ATTRIBUTION.md.
// Exo upstream: https://github.com/debuggyo/Exo
//
// OnixSpin: numeric stepper (ports upstream SpinButton).
import QtQuick

Row {
    id: root

    property real min: 0
    property real max: 100
    property real step: 1
    property real value: 0
    signal changed(real value)

    spacing: 8

    M3Button {
        anchors.verticalCenter: parent.verticalCenter
        btnType: "tonal"
        size: "xs"
        icon: "remove"
        onClicked: {
            var v = Math.max(root.min, root.value - root.step);
            root.changed(v);
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        horizontalAlignment: Text.AlignHCenter
        text: Number.isInteger(root.value) ? root.value.toString() : root.value.toFixed(1)
        color: OnixTheme.mOnSurface
        font.pixelSize: OnixTheme.fontMed
        font.bold: true
    }

    M3Button {
        anchors.verticalCenter: parent.verticalCenter
        btnType: "tonal"
        size: "xs"
        icon: "add"
        onClicked: {
            var v = Math.min(root.max, root.value + root.step);
            root.changed(v);
        }
    }
}
