import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root
    anchors.fill: parent

    property bool menuOpen: false
    property int  selectedIndex: 0
    readonly property int buttonCount: 6

    function openMenu() {
        menuOpen = true
        selectedIndex = 0
        wipeHost.visible = true
        wipeHost.opacity = 0
        fadeIn.start()
        wipeHost.forceActiveFocus()
    }

    function closeMenu() {
        fadeOut.start()
    }

    IpcHandler {
        target: "power"
        function toggle(): void { menuOpen ? root.closeMenu() : root.openMenu() }
        function open(): void   { if (!menuOpen) root.openMenu() }
        function close(): void  { if ( menuOpen) root.closeMenu() }
    }

    NumberAnimation {
        id: fadeIn; target: wipeHost; property: "opacity"
        from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutQuad
    }
    NumberAnimation {
        id: fadeOut; target: wipeHost; property: "opacity"
        from: 1.0; to: 0.0; duration: 150; easing.type: Easing.InQuad
        onFinished: { wipeHost.visible = false; root.menuOpen = false }
    }

    // Click-off to close
    MouseArea {
        anchors.fill: parent; visible: root.menuOpen; z: 0
        onClicked: root.closeMenu()
    }

    Item {
        id: wipeHost
        width: 520
        anchors.centerIn: parent
        visible: false; opacity: 0; z: 1
        implicitHeight: menuCol.implicitHeight + 32
        height: implicitHeight
        focus: true

        property bool physicallyHeld: false
        property int  heldIndex: 0

        Timer {
            id: releaseDebounce
            interval: 80; repeat: false; running: false
            onTriggered: {
                wipeHost.physicallyHeld = false
                btnRepeater.itemAt(wipeHost.heldIndex).keyRelease()
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.closeMenu(); event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                root.selectedIndex = (root.selectedIndex - 1 + root.buttonCount) % root.buttonCount
                event.accepted = true
            } else if (event.key === Qt.Key_Down) {
                root.selectedIndex = (root.selectedIndex + 1) % root.buttonCount
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                releaseDebounce.stop()
                if (!physicallyHeld) {
                    physicallyHeld = true
                    heldIndex = root.selectedIndex
                    btnRepeater.itemAt(heldIndex).keyActivate()
                }
                event.accepted = true
            }
        }
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                releaseDebounce.restart()
                event.accepted = true
            }
        }

        // Consume clicks inside panel
        MouseArea { anchors.fill: parent; onClicked: {} }

        Rectangle { anchors.fill: parent; color: Qt.rgba(11/255,10/255,9/255,0.92) }

        // Corner accents — matching HudPanel sepia style
        Rectangle { x:0;  y:0;  width:16; height:1; color:Qt.rgba(200/255,184/255,154/255,0.5) }
        Rectangle { x:0;  y:0;  width:1;  height:16; color:Qt.rgba(200/255,184/255,154/255,0.5) }
        Rectangle { x:parent.width-16; y:0; width:16; height:1; color:Qt.rgba(200/255,184/255,154/255,0.5) }
        Rectangle { x:parent.width-1;  y:0; width:1; height:16; color:Qt.rgba(200/255,184/255,154/255,0.5) }
        Rectangle { x:0;  y:parent.height-1; width:16; height:1; color:Qt.rgba(200/255,184/255,154/255,0.5) }
        Rectangle { x:0;  y:parent.height-16; width:1; height:16; color:Qt.rgba(200/255,184/255,154/255,0.5) }
        Rectangle { x:parent.width-16; y:parent.height-1; width:16; height:1; color:Qt.rgba(200/255,184/255,154/255,0.5) }
        Rectangle { x:parent.width-1;  y:parent.height-16; width:1; height:16; color:Qt.rgba(200/255,184/255,154/255,0.5) }
        // Outer border
        Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Qt.rgba(200/255,184/255,154/255,0.15) }
        // Title bar bottom line
        Rectangle { x:0; y:52; width:parent.width; height:1; color:Qt.rgba(200/255,184/255,154/255,0.08) }

        Column {
            id: menuCol
            anchors { fill: parent; topMargin: 20; bottomMargin: 20; leftMargin: 20; rightMargin: 20 }
            spacing: 0

            // Title
            Row {
                width: parent.width; height: 32; spacing: 8
                Rectangle {
                    width: 6; height: 6; anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(200/255,168/255,74/255,0.9)
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite; running: root.menuOpen
                        NumberAnimation { to: 0.2; duration: 900 }
                        NumberAnimation { to: 1.0; duration: 900 }
                    }
                }
                Text {
                    text: "SYSTEM"; font.family: "Share Tech Mono"; font.pixelSize: 12
                    font.letterSpacing: 3; font.weight: Font.DemiBold
                    color: Qt.rgba(200/255,168/255,74/255,0.9); anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "—— 電源管理"; font.family: "Share Tech Mono"; font.pixelSize: 9
                    font.letterSpacing: 1; color: Qt.rgba(200/255,184/255,154/255,0.35)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(200/255,184/255,154/255,0.08) }
            Item { width: 1; height: 12 }

            // Buttons via Repeater for keyboard nav
            Repeater {
                id: btnRepeater
                model: [
                    { label: "LOCK",           icon: "⬡", accent: "#4a9a6a",  hold: false, duration: 0,    warningText: "",  bgTint: "" },
                    { label: "SUSPEND",         icon: "◎", accent: "#c8b89a",  hold: false, duration: 0,    warningText: "",  bgTint: "" },
                    { label: "LOGOUT",          icon: "◈", accent: "#c8a84a",  hold: false, duration: 0,    warningText: "",  bgTint: "" },
                    { label: "REBOOT",          icon: "↺", accent: "#c8a84a",  hold: true,  duration: 1500, warningText: "↺ REBOOTING // システム再起動 // ALL SESSIONS WILL END // 再起動中 // SAVING STATE // プロセス終了 // RESTARTING // カーネル再起動 // ↺ ",  bgTint: "#c8a84a" },
                    { label: "REBOOT TO UEFI",  icon: "⬡", accent: "#c8a84a",  hold: true,  duration: 1500, warningText: "⬡ ENTERING FIRMWARE // UEFI設定 // SYSTEM WILL RESTART // ファームウェア // BIOS ACCESS // 設定モード // HARDWARE INIT // ブート設定 // ⬡ ", bgTint: "#c8a84a" },
                    { label: "SHUTDOWN",        icon: "⏻", accent: "#c85a3a",  hold: true,  duration: 2000, warningText: "⚠ WARNING // IMMINENT SHUTDOWN // データ消去 // ALL PROCESSES WILL TERMINATE // システム停止 // POWER OFF // 電源切断 // UNSAVED DATA WILL BE LOST // 終了中 // ⚠ ", bgTint: "#c85a3a" },
                ]

                Item {
                    id: btnItem
                    width: parent.width
                    height: index === 3 ? 58 : 46  // extra top spacing before hold section
                    property bool isSelected: root.selectedIndex === index
                    property real holdProgress: 0

                    function keyActivate() {
                        if (!modelData.hold) {
                            fireAction()
                        } else if (!holdTimer.running) {
                            holdTimer.elapsed = 0
                            holdTimer.running = true
                        }
                    }
                    function keyRelease() {
                        if (modelData.hold && holdTimer.running) {
                            holdTimer.running = false
                            holdProgress = 0
                            holdTimer.elapsed = 0
                        }
                    }
                    function fireAction() {
                        var cmds = [
                            ["hyprlock"],
                            ["systemctl","suspend"],
                            ["hyprctl","dispatch","exit"],
                            ["systemctl","reboot"],
                            ["systemctl","reboot","--firmware-setup"],
                            ["systemctl","poweroff"]
                        ]
                        actionProc.command = cmds[index]
                        actionProc.running = true
                        if (index <= 1) root.closeMenu()
                    }

                    // Separator line before hold section
                    Rectangle {
                        visible: index === 3
                        anchors.top: parent.top; width: parent.width; height: 1
                        color: Qt.rgba(200/255,184/255,154/255,0.06)
                    }

                    // Button area — positioned at bottom of item
                    Item {
                        id: btnArea
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 46
                        clip: true

                        property bool hovered: btnItem.isSelected || ma.containsMouse

                        // Background tint for hold buttons
                        Rectangle {
                            anchors.fill: parent
                            color: modelData.bgTint !== "" && btnArea.hovered
                                ? Qt.rgba(
                                    parseInt(modelData.bgTint.slice(1,3),16)/255,
                                    parseInt(modelData.bgTint.slice(3,5),16)/255,
                                    parseInt(modelData.bgTint.slice(5,7),16)/255,
                                    modelData.label === "SHUTDOWN" ? 0.12 : 0.07)
                                : Qt.rgba(200/255,184/255,154/255, btnArea.hovered ? 0.06 : 0.0)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        // Rolling warning text — only on hold buttons when hovered
                        Item {
                            id: warningTickerItem
                            anchors.fill: parent
                            visible: modelData.warningText !== "" && btnArea.hovered
                            clip: true
                            opacity: 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            onVisibleChanged: if (visible) opacity = 1

                            // Glitch chars pool
                            property string glitchChars: "█▓▒░⚡⚠↯▲◆◈⬡⏻01"
                            property string glitchOverlay: ""

                            // Glitch timer — fires faster as hold progresses, starts on hover
                            Timer {
                                id: glitchTimer
                                interval: {
                                    var base = modelData.label === "SHUTDOWN" ? 350 : 500
                                    var min  = modelData.label === "SHUTDOWN" ? 40  : 80
                                    return Math.max(min, base - btnItem.holdProgress * (base - min))
                                }
                                running: btnArea.hovered && modelData.hold
                                repeat: true
                                onTriggered: {
                                    var chars = "█▓▒░⚡⚠↯▲◆◈⬡⏻01"
                                    var count = Math.max(1, Math.ceil(btnItem.holdProgress * 6 + 1))
                                    var result = ""
                                    for (var i = 0; i < count; i++) {
                                        result += chars[Math.floor(Math.random() * chars.length)]
                                        if (i < count - 1) result += " "
                                    }
                                    warningTickerItem.glitchOverlay = result
                                    glitchClearTimer.restart()
                                }
                            }

                            // Clear glitch after brief flash
                            Timer {
                                id: glitchClearTimer
                                interval: Math.max(30, 80 - btnItem.holdProgress * 50)
                                repeat: false; running: false
                                onTriggered: warningTickerItem.glitchOverlay = ""
                            }

                            Text {
                                id: warningTicker
                                text: modelData.warningText + modelData.warningText
                                font.family: "Share Tech Mono"
                                font.pixelSize: modelData.label === "SHUTDOWN" ? 10 : 9
                                font.letterSpacing: 1.5
                                color: modelData.bgTint !== ""
                                    ? Qt.rgba(
                                        parseInt(modelData.bgTint.slice(1,3),16)/255,
                                        parseInt(modelData.bgTint.slice(3,5),16)/255,
                                        parseInt(modelData.bgTint.slice(5,7),16)/255,
                                        modelData.label === "SHUTDOWN" ? 0.35 : 0.25)
                                    : "transparent"
                                anchors.verticalCenter: parent.verticalCenter

                                NumberAnimation on x {
                                    id: warningTickerAnim
                                    from: 0; to: -warningTicker.implicitWidth / 2
                                    duration: modelData.label === "SHUTDOWN" ? 8000 : 12000
                                    loops: Animation.Infinite
                                    running: modelData.warningText !== "" && btnArea.hovered
                                    easing.type: Easing.Linear
                                }
                                Component.onCompleted: if (modelData.warningText !== "") warningTickerAnim.restart()
                            }

                            // Glitch overlay — flashes random chars at a random x position
                            Text {
                                visible: warningTickerItem.glitchOverlay !== ""
                                text: warningTickerItem.glitchOverlay
                                font.family: "Share Tech Mono"
                                font.pixelSize: modelData.label === "SHUTDOWN" ? 11 : 10
                                font.letterSpacing: 2
                                font.weight: Font.Bold
                                color: modelData.label === "SHUTDOWN"
                                    ? Qt.rgba(1.0, 0.35, 0.18, 0.7 + btnItem.holdProgress * 0.3)
                                    : Qt.rgba(200/255, 168/255, 74/255, 0.6 + btnItem.holdProgress * 0.3)
                                anchors.verticalCenter: parent.verticalCenter
                                x: 80 + Math.random() * (parent.width - 180)
                                z: 2
                            }

                            // Left fade
                            Rectangle {
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                width: 80; z: 3
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: Qt.rgba(11/255,10/255,9/255,0.95) }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }
                            // Right fade
                            Rectangle {
                                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                                width: 90; z: 3
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.5; color: Qt.rgba(11/255,10/255,9/255,0.85) }
                                    GradientStop { position: 1.0; color: Qt.rgba(11/255,10/255,9/255,0.95) }
                                }
                            }
                        }

                        // Hold progress bar
                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left }
                            width: parent.width * btnItem.holdProgress
                            height: 2; color: modelData.accent; opacity: 0.9
                            visible: modelData.hold
                        }

                        // Left accent
                        Rectangle {
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width: 2; color: modelData.accent
                            opacity: btnArea.hovered ? 0.8 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        Row {
                            anchors { fill: parent; leftMargin: 16; rightMargin: 12 }
                            spacing: 14
                            z: 2

                            Text {
                                id: iconTxt
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                font.pixelSize: modelData.label === "SHUTDOWN" ? 16 : 13
                                color: modelData.accent; opacity: 0.85
                            }
                            Text {
                                id: labelTxt
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                font.family: "Share Tech Mono"; font.pixelSize: 13
                                font.letterSpacing: 2; font.weight: Font.DemiBold
                                color: btnArea.hovered ? modelData.accent : Qt.rgba(232/255,216/255,184/255,0.8)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Item { width: parent.width - iconTxt.implicitWidth - labelTxt.implicitWidth - holdTxt.implicitWidth - 42; height: 1 }
                            Text {
                                id: holdTxt
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.hold
                                text: "hold"
                                font.family: "Share Tech Mono"; font.pixelSize: 8; font.letterSpacing: 1
                                color: Qt.rgba(200/255,184/255,154/255,0.25)
                            }
                        }

                        MouseArea {
                            id: ma; anchors.fill: parent; hoverEnabled: true; z: 3
                            onEntered:  root.selectedIndex = index
                            onClicked:  { if (!modelData.hold) btnItem.fireAction() }
                            onPressed:  { if (modelData.hold) { holdTimer.elapsed=0; holdTimer.running=true } }
                            onReleased: { if (modelData.hold) { holdTimer.running=false; btnItem.holdProgress=0; holdTimer.elapsed=0 } }
                            onExited:   { if (modelData.hold && holdTimer.running) { holdTimer.running=false; btnItem.holdProgress=0; holdTimer.elapsed=0 } }
                        }
                    }

                    Timer {
                        id: holdTimer; interval: 16; repeat: true; running: false
                        property real elapsed: 0
                        onTriggered: {
                            elapsed += 16
                            btnItem.holdProgress = Math.min(1.0, elapsed / modelData.duration)
                            if (elapsed >= modelData.duration) {
                                running = false
                                btnItem.fireAction()
                                btnItem.holdProgress = 0
                                elapsed = 0
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 14 }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(200/255,184/255,154/255,0.06) }
            Item { width: 1; height: 10 }

            // Footer
            Row {
                width: parent.width
                Text {
                    text: "TTY2  //  chvt 2"
                    font.family: "Share Tech Mono"; font.pixelSize: 8; font.letterSpacing: 1
                    color: Qt.rgba(200/255,184/255,154/255,0.2)
                }
                Item { width: 1; height: 1
                    anchors.horizontalCenter: undefined
                    Component.onCompleted: width = parent.width - footerLeft.implicitWidth - footerRight.implicitWidth
                }
                Text {
                    id: footerRight
                    property string t: "--:--"
                    text: t
                    font.family: "Share Tech Mono"; font.pixelSize: 8; font.letterSpacing: 1
                    color: Qt.rgba(200/255,184/255,154/255,0.2)
                    Timer {
                        interval: 1000; running: true; repeat: true
                        onTriggered: {
                            var d = new Date()
                            parent.t = String(d.getHours()).padStart(2,"0") + ":" + String(d.getMinutes()).padStart(2,"0")
                        }
                    }
                }
                Text { id: footerLeft; visible: false; text: "TTY2  //  chvt 2" }
            }
        }
    }

    // Single process reused for all actions
    Process {
        id: actionProc
        command: []
        running: false
    }
}
