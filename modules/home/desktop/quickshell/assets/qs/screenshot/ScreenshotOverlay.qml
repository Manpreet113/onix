import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.theme

PanelWindow {
    id: win

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "onix-screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ScreenshotState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: ScreenshotState.open

    // Normalized selection properties
    readonly property real selLeft: Math.min(ScreenshotState.selX, ScreenshotState.selX + ScreenshotState.selW)
    readonly property real selTop: Math.min(ScreenshotState.selY, ScreenshotState.selY + ScreenshotState.selH)
    readonly property real selWidth: Math.abs(ScreenshotState.selW)
    readonly property real selHeight: Math.abs(ScreenshotState.selH)

    // Keyboard navigation
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: ScreenshotState.open
        Keys.onEscapePressed: {
            if (ScreenshotState.hasSelection) {
                ScreenshotState.selW = 0;
                ScreenshotState.selH = 0;
            } else {
                ScreenshotState.cancel();
            }
        }
        Keys.onReturnPressed: {
            if (ScreenshotState.mode === "fullscreen")
                ScreenshotState.captureFullscreen();
            else if (ScreenshotState.mode === "region") {
                if (ScreenshotState.hasSelection)
                    ScreenshotState.captureSelection();
                else
                    ScreenshotState.captureFullscreen();
            } else if (ScreenshotState.mode === "window" && ScreenshotState.hoveredWindow)
                ScreenshotState.captureWindow(ScreenshotState.hoveredWindow);
        }
    }

    Connections {
        target: ScreenshotState
        function onOpenChanged() {
            if (ScreenshotState.open) {
                keyHandler.forceActiveFocus();
            }
        }
    }

    // Freeze-Frame image backdrop
    Image {
        id: freezeImg
        anchors.fill: parent
        source: ScreenshotState.freezeUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: false
    }

    // ==========================================
    // 1. REGION MODE: 4-Way Darkened Scrim Cutout
    // ==========================================
    Item {
        id: regionContainer
        anchors.fill: parent
        visible: ScreenshotState.mode === "region"

        // Background canvas dragging MouseArea (z: 1)
        MouseArea {
            id: dragArea
            anchors.fill: parent
            z: 1
            cursorShape: Qt.CrossCursor

            property real startX: 0
            property real startY: 0
            property bool isDragging: false

            onPressed: mouse => {
                startX = mouse.x;
                startY = mouse.y;
                ScreenshotState.selX = mouse.x;
                ScreenshotState.selY = mouse.y;
                ScreenshotState.selW = 0;
                ScreenshotState.selH = 0;
                isDragging = true;
            }

            onPositionChanged: mouse => {
                if (!isDragging)
                    return;
                ScreenshotState.selX = Math.min(startX, mouse.x);
                ScreenshotState.selY = Math.min(startY, mouse.y);
                ScreenshotState.selW = Math.abs(mouse.x - startX);
                ScreenshotState.selH = Math.abs(mouse.y - startY);
            }

            onReleased: mouse => {
                isDragging = false;
                if (ScreenshotState.selW < 8 || ScreenshotState.selH < 8) {
                    ScreenshotState.selW = 0;
                    ScreenshotState.selH = 0;
                }
            }
        }

        // Top Scrim
        Rectangle {
            z: 2
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: ScreenshotState.hasSelection ? win.selTop : parent.height
            color: Qt.rgba(0, 0, 0, 0.48)
        }

        // Bottom Scrim
        Rectangle {
            z: 2
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: ScreenshotState.hasSelection ? Math.max(0, parent.height - (win.selTop + win.selHeight)) : 0
            color: Qt.rgba(0, 0, 0, 0.48)
            visible: ScreenshotState.hasSelection
        }

        // Left Scrim
        Rectangle {
            z: 2
            y: win.selTop
            x: 0
            width: ScreenshotState.hasSelection ? win.selLeft : 0
            height: win.selHeight
            color: Qt.rgba(0, 0, 0, 0.48)
            visible: ScreenshotState.hasSelection
        }

        // Right Scrim
        Rectangle {
            z: 2
            y: win.selTop
            x: win.selLeft + win.selWidth
            width: ScreenshotState.hasSelection ? Math.max(0, parent.width - (win.selLeft + win.selWidth)) : 0
            height: win.selHeight
            color: Qt.rgba(0, 0, 0, 0.48)
            visible: ScreenshotState.hasSelection
        }

        // Selection Box Rectangle (z: 10, above scrims and drag area)
        Rectangle {
            id: selectionBox
            z: 10
            x: win.selLeft
            y: win.selTop
            width: win.selWidth
            height: win.selHeight
            visible: ScreenshotState.hasSelection
            color: "transparent"
            border.color: Theme.accent
            border.width: 2

            // Move & Double-click capture MouseArea
            MouseArea {
                id: boxMover
                anchors.fill: parent
                anchors.margins: 6
                cursorShape: Qt.SizeAllCursor

                property real dragStartX: 0
                property real dragStartY: 0
                property real initX: 0
                property real initY: 0
                property bool isMoving: false

                onPressed: mouse => {
                    dragStartX = mouse.x;
                    dragStartY = mouse.y;
                    initX = ScreenshotState.selX;
                    initY = ScreenshotState.selY;
                    isMoving = true;
                }

                onPositionChanged: mouse => {
                    if (!isMoving)
                        return;
                    const dx = mouse.x - dragStartX;
                    const dy = mouse.y - dragStartY;
                    const maxX = Math.max(0, regionContainer.width - ScreenshotState.selW);
                    const maxY = Math.max(0, regionContainer.height - ScreenshotState.selH);
                    ScreenshotState.selX = Math.max(0, Math.min(maxX, initX + dx));
                    ScreenshotState.selY = Math.max(0, Math.min(maxY, initY + dy));
                }

                onReleased: mouse => {
                    isMoving = false;
                }

                onDoubleClicked: ScreenshotState.captureSelection()
            }

            // Dimension Badge
            Rectangle {
                anchors.bottom: parent.top
                anchors.bottomMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                height: 24
                implicitWidth: dimText.implicitWidth + 16
                radius: 12
                color: Theme.glassBg
                border.color: Theme.accent
                border.width: 1
                visible: selectionBox.y >= 36

                Text {
                    id: dimText
                    anchors.centerIn: parent
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.text
                    text: Math.round(win.selWidth) + " × " + Math.round(win.selHeight) + " px"
                }
            }

            // Top-Left Corner Handle
            Rectangle {
                x: -5
                y: -5
                width: 10
                height: 10
                radius: 2
                color: Theme.text
                border.color: Theme.accent
                border.width: 1

                MouseArea {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    cursorShape: Qt.SizeFDiagCursor
                    property real initRight: 0
                    property real initBottom: 0
                    property bool active: false

                    onPressed: mouse => {
                        initRight = ScreenshotState.selX + ScreenshotState.selW;
                        initBottom = ScreenshotState.selY + ScreenshotState.selH;
                        active = true;
                    }
                    onPositionChanged: mouse => {
                        if (!active) return;
                        const p = mapToItem(regionContainer, mouse.x, mouse.y);
                        const newX = Math.max(0, Math.min(initRight - 16, p.x));
                        const newY = Math.max(0, Math.min(initBottom - 16, p.y));
                        ScreenshotState.selX = newX;
                        ScreenshotState.selY = newY;
                        ScreenshotState.selW = initRight - newX;
                        ScreenshotState.selH = initBottom - newY;
                    }
                    onReleased: active = false
                }
            }

            // Top-Right Corner Handle
            Rectangle {
                x: selectionBox.width - 5
                y: -5
                width: 10
                height: 10
                radius: 2
                color: Theme.text
                border.color: Theme.accent
                border.width: 1

                MouseArea {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    cursorShape: Qt.SizeBDiagCursor
                    property real initX: 0
                    property real initBottom: 0
                    property bool active: false

                    onPressed: mouse => {
                        initX = ScreenshotState.selX;
                        initBottom = ScreenshotState.selY + ScreenshotState.selH;
                        active = true;
                    }
                    onPositionChanged: mouse => {
                        if (!active) return;
                        const p = mapToItem(regionContainer, mouse.x, mouse.y);
                        const newY = Math.max(0, Math.min(initBottom - 16, p.y));
                        const newR = Math.min(regionContainer.width, Math.max(initX + 16, p.x));
                        ScreenshotState.selY = newY;
                        ScreenshotState.selW = newR - initX;
                        ScreenshotState.selH = initBottom - newY;
                    }
                    onReleased: active = false
                }
            }

            // Bottom-Left Corner Handle
            Rectangle {
                x: -5
                y: selectionBox.height - 5
                width: 10
                height: 10
                radius: 2
                color: Theme.text
                border.color: Theme.accent
                border.width: 1

                MouseArea {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    cursorShape: Qt.SizeBDiagCursor
                    property real initRight: 0
                    property real initY: 0
                    property bool active: false

                    onPressed: mouse => {
                        initRight = ScreenshotState.selX + ScreenshotState.selW;
                        initY = ScreenshotState.selY;
                        active = true;
                    }
                    onPositionChanged: mouse => {
                        if (!active) return;
                        const p = mapToItem(regionContainer, mouse.x, mouse.y);
                        const newX = Math.max(0, Math.min(initRight - 16, p.x));
                        const newB = Math.min(regionContainer.height, Math.max(initY + 16, p.y));
                        ScreenshotState.selX = newX;
                        ScreenshotState.selW = initRight - newX;
                        ScreenshotState.selH = newB - initY;
                    }
                    onReleased: active = false
                }
            }

            // Bottom-Right Corner Handle
            Rectangle {
                x: selectionBox.width - 5
                y: selectionBox.height - 5
                width: 10
                height: 10
                radius: 2
                color: Theme.text
                border.color: Theme.accent
                border.width: 1

                MouseArea {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    cursorShape: Qt.SizeFDiagCursor
                    property real initX: 0
                    property real initY: 0
                    property bool active: false

                    onPressed: mouse => {
                        initX = ScreenshotState.selX;
                        initY = ScreenshotState.selY;
                        active = true;
                    }
                    onPositionChanged: mouse => {
                        if (!active) return;
                        const p = mapToItem(regionContainer, mouse.x, mouse.y);
                        const newR = Math.min(regionContainer.width, Math.max(initX + 16, p.x));
                        const newB = Math.min(regionContainer.height, Math.max(initY + 16, p.y));
                        ScreenshotState.selW = newR - initX;
                        ScreenshotState.selH = newB - initY;
                    }
                    onReleased: active = false
                }
            }

            // Quick Actions Floating Toolbar (Snip, Annotate, Copy, Dismiss)
            Rectangle {
                id: quickBar
                z: 20
                anchors.top: parent.bottom
                anchors.topMargin: (selectionBox.y + selectionBox.height + 48 > regionContainer.height) ? -42 : 10
                width: quickRow.implicitWidth + 18
                height: 34
                x: Math.max(12 - selectionBox.x, Math.min(selectionBox.width - width, regionContainer.width - selectionBox.x - width - 12))
                visible: ScreenshotState.hasSelection && !dragArea.isDragging
                radius: 17
                color: Theme.glassBg
                border.color: Theme.glassBorder
                border.width: 1

                RowLayout {
                    id: quickRow
                    anchors.centerIn: parent
                    spacing: 5

                    // Capture / Confirm Button
                    Rectangle {
                        height: 26
                        implicitWidth: capRow.implicitWidth + 14
                        radius: 13
                        color: Theme.accent

                        RowLayout {
                            id: capRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                font.family: Theme.fontIcons
                                font.pixelSize: 14
                                color: Theme.background
                                text: "check"
                            }

                            Text {
                                font.family: Theme.fontPrimary
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: Theme.background
                                text: "Capture"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ScreenshotState.captureSelection()
                        }
                    }

                    // Annotate / Edit Button
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: annMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                        border.color: Theme.cardBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 13
                            color: Theme.text
                            text: "edit"
                        }

                        MouseArea {
                            id: annMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ScreenshotState.annotateAfter = true;
                                ScreenshotState.captureSelection();
                            }
                        }
                    }

                    // Copy to Clipboard Button
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: copyMouse.containsMouse ? Theme.chipHover : Theme.chipBg
                        border.color: Theme.cardBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 13
                            color: Theme.text
                            text: "content_copy"
                        }

                        MouseArea {
                            id: copyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ScreenshotState.copyToClipboard = true;
                                ScreenshotState.captureSelection();
                            }
                        }
                    }

                    // Clear Selection Button
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: clearMouse.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.20) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontIcons
                            font.pixelSize: 13
                            color: clearMouse.containsMouse ? Theme.error : Theme.dim
                            text: "close"
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ScreenshotState.selW = 0;
                                ScreenshotState.selH = 0;
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // 2. WINDOW MODE: Hover & Select Window
    // ==========================================
    Item {
        anchors.fill: parent
        visible: ScreenshotState.mode === "window"

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
        }

        // Highlight for hovered window
        Rectangle {
            visible: ScreenshotState.hoveredWindow !== null
            x: ScreenshotState.hoveredWindow ? ScreenshotState.hoveredWindow.at[0] : 0
            y: ScreenshotState.hoveredWindow ? ScreenshotState.hoveredWindow.at[1] : 0
            width: ScreenshotState.hoveredWindow ? ScreenshotState.hoveredWindow.size[0] : 0
            height: ScreenshotState.hoveredWindow ? ScreenshotState.hoveredWindow.size[1] : 0
            radius: 12
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
            border.color: Theme.accent
            border.width: 2

            // Window Title Badge
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 12
                height: 28
                implicitWidth: winTitleRow.implicitWidth + 18
                radius: 14
                color: Theme.glassBg
                border.color: Theme.accent
                border.width: 1

                RowLayout {
                    id: winTitleRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        font.family: Theme.fontIcons
                        font.pixelSize: 14
                        color: Theme.accent
                        text: "window"
                    }

                    Text {
                        font.family: Theme.fontPrimary
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.text
                        text: ScreenshotState.hoveredWindow ? (ScreenshotState.hoveredWindow.title || ScreenshotState.hoveredWindow.class) : ""
                        elide: Text.ElideRight
                        Layout.maximumWidth: 260
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onPositionChanged: mouse => {
                const mx = mouse.x;
                const my = mouse.y;
                let found = null;
                for (let i = 0; i < ScreenshotState.windows.length; i++) {
                    const w = ScreenshotState.windows[i];
                    const wx = w.at[0];
                    const wy = w.at[1];
                    const ww = w.size[0];
                    const wh = w.size[1];
                    if (mx >= wx && mx <= wx + ww && my >= wy && my <= wy + wh) {
                        found = w;
                        break;
                    }
                }
                ScreenshotState.hoveredWindow = found;
            }

            onClicked: {
                if (ScreenshotState.hoveredWindow) {
                    ScreenshotState.captureWindow(ScreenshotState.hoveredWindow);
                }
            }
        }
    }

    // ==========================================
    // 3. FULLSCREEN MODE: Full Screen Indicator
    // ==========================================
    Item {
        anchors.fill: parent
        visible: ScreenshotState.mode === "fullscreen"

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)
            border.color: fullMouse.containsMouse ? Theme.accent : "transparent"
            border.width: fullMouse.containsMouse ? 3 : 0
        }

        MouseArea {
            id: fullMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ScreenshotState.captureFullscreen()
        }
    }

    // ==========================================
    // COUNTDOWN OVERLAY
    // ==========================================
    Rectangle {
        anchors.centerIn: parent
        width: 120
        height: 120
        radius: 60
        color: Theme.glassBg
        border.color: Theme.accent
        border.width: 2
        visible: ScreenshotState.countdown > 0

        Text {
            anchors.centerIn: parent
            font.family: Theme.fontDisplay
            font.pixelSize: 52
            font.weight: Font.Bold
            color: Theme.accent
            text: ScreenshotState.countdown
        }
    }

    // ==========================================
    // FLOATING CONTROL HUD
    // ==========================================
    ScreenshotHud {
        anchors.top: parent.top
        anchors.topMargin: 64
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // Helper banner at bottom
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        height: 28
        implicitWidth: hintText.implicitWidth + 24
        radius: 14
        color: Theme.glassBg
        border.color: Theme.glassBorder
        border.width: 1
        visible: !ScreenshotState.hasSelection

        Text {
            id: hintText
            anchors.centerIn: parent
            font.family: Theme.fontPrimary
            font.pixelSize: 11
            color: Theme.dim
            text: {
                if (ScreenshotState.mode === "region")
                    return "Drag to snip a region • Double-click or press Enter to capture • ESC to cancel";
                if (ScreenshotState.mode === "window")
                    return "Hover over any window and click to capture it • ESC to cancel";
                return "Click anywhere to capture entire screen • ESC to cancel";
            }
        }
    }
}
