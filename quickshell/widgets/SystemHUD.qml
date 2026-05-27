import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // ── State ──
    property bool visible_: true
    property string cpuUsage:  "0"
    property string cpuTemp:   "?"
    property string gpuUsage:  "0"
    property string gpuTemp:   "?"
    property string ramUsage:  "0"
    property string ramTotal:  "0"
    property string netDown:   "0"
    property string netUp:     "0"
    property real   netTotalRx: 0
    property real   netTotalTx: 0
    property var    downHistory: []
    property var    upHistory:   []
    property real   wavePhase:   0
    property real   smoothDl:    0
    property real   smoothUl:    0

    onNetDownChanged: downHistory = pushHistory(downHistory, parseInt(netDown) || 0)
    onNetUpChanged:   upHistory   = pushHistory(upHistory,   parseInt(netUp)   || 0)
    property string uptime:    "..."
    property string kernel:    "..."
    property string hostname:  "YoRHa"
    property int    tick:      0
    property int    scanY:     0
    property var    cavaBars:  []

    // ── Palette (matching Player.qml dark theme) ──
    readonly property color paper:    "#0b0a09"
    readonly property color ink:      "#c8b89a"
    readonly property color inkStrong:"#e8d8b8"
    readonly property color inkSoft:  "#8a7a62"
    readonly property color lineSoft: Qt.rgba(200/255,184/255,154/255,0.18)
    readonly property color lineVsoft:Qt.rgba(200/255,184/255,154/255,0.08)
    readonly property color accent:   "#c8b89a"
    readonly property color accentGold:"#c8a84a"
    readonly property color green:    "#4a9a6a"

    // ── Format helpers (on root so any child can call root.fmt / root.fmtRate) ──
    function fmtRate(b) {
        if (b > 1048576) return (b/1048576).toFixed(1) + " MB/s"
        if (b > 1024)    return (b/1024).toFixed(1)    + " KB/s"
        return b + " B/s"
    }
    function fmt(b) {
        if (b > 1073741824) return (b/1073741824).toFixed(2) + " GB"
        if (b > 1048576)    return (b/1048576).toFixed(1)    + " MB"
        if (b > 1024)       return (b/1024).toFixed(1)       + " KB"
        return b + " B"
    }

    // ── Scanline animation ──
    Timer {
        interval: 16; running: true; repeat: true
        onTriggered: root.scanY = (root.scanY + 1) % 600
    }

    // ── Blink tick ──
    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: root.tick = (root.tick + 1) % 4
    }

    // ── Mission log ──
    property var missionLog: [
        "[ BOOT ] YoRHa tactical systems online",
        "[ SYNC ] Pod link established",
        "[ SCAN ] Environment analysis complete",
        "[ INFO ] Stealth camouflage: standby",
        "[ WARN ] Anomalous machine activity detected",
        "[ INFO ] Weapons systems nominal",
        "[ SYNC ] Black Box integrity: 100%",
        "[ SCAN ] Threat level: moderate",
        "[ INFO ] Memory banks operating normally",
        "[ SYNC ] Command uplink: stable",
        "[ INFO ] Flight unit ready",
        "[ WARN ] Unidentified signal — sector 7",
        "[ TASK ] Eliminate all machine lifeforms",
        "[ SCAN ] Hostiles in range: 3",
        "[ WARN ] Emotion data fluctuation detected",
        "[ INFO ] Pod program charged",
        "[ SYNC ] Bunker signal strength: optimal",
        "[ INFO ] Glory to Mankind",
    ]
    property int logIndex: 0
    Timer {
        interval: 3500; running: true; repeat: true
        onTriggered: root.logIndex = (root.logIndex + 1) % root.missionLog.length
    }

    // ── Rolling ticker text ──
    property string tickerText: "接続中 // COMBAT SYSTEMS ACTIVE // データ処理中 // SYS:NOMINAL // YoRHa TYPE-A // 全システム正常 // STANDING BY // 脅威レベル:中 // POD LINK ESTABLISHED // FOR THE GLORY OF MANKIND // "

    // ── IPC toggle ──
    IpcHandler {
        target: "hud"
        function toggle(): void { root.visible_ = !root.visible_ }
    }

    // ── Waveform phase animation ──
    Timer {
        interval: 16; running: true; repeat: true
        onTriggered: {
            root.wavePhase = root.wavePhase + 0.04
            var targetDl = Math.min(parseInt(root.netDown) || 0, 10000000)
            var targetUl = Math.min(parseInt(root.netUp)   || 0, 10000000)
            root.smoothDl = root.smoothDl + (targetDl - root.smoothDl) * 0.05
            root.smoothUl = root.smoothUl + (targetUl - root.smoothUl) * 0.05
        }
    }

    // ── Stats polling ──
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: {
            cpuProc.running = true
            ramProc.running = true
            gpuProc.running = true
            netProc.running = true
            uptimeProc.running = true
            kernelProc.running = true
            hostnameProc.running = true
            // Push history
            root.cpuHistory  = root.pushHistory(root.cpuHistory, parseFloat(root.cpuUsage) || 0)
            root.gpuHistory  = root.pushHistory(root.gpuHistory, parseFloat(root.gpuUsage) || 0)
            var memPct = root.ramTotal > 0 ? (parseInt(root.ramUsage) / parseInt(root.ramTotal) * 100) : 0
            root.memHistory  = root.pushHistory(root.memHistory, memPct)
        }
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}'; cat /sys/class/hwmon/hwmon4/temp1_input"]
        running: true
        stdout: SplitParser {
            property int ln: 0
            onRead: data => {
                var v = data.trim()
                if (ln === 0 && v !== "" && !isNaN(parseFloat(v))) root.cpuUsage = Math.round(parseFloat(v)) + ""
                if (ln === 1 && v !== "") root.cpuTemp = Math.round(parseInt(v)/1000) + ""
                ln = (ln + 1) % 2
            }
        }
    }
    Process {
        id: ramProc
        command: ["sh", "-c", "free -m | awk 'NR==2{print $3\"/\"$2}'"]
        running: true
        stdout: SplitParser { onRead: data => { var p = data.trim().split("/"); if (p.length===2) { root.ramUsage = p[0]; root.ramTotal = p[1] } } }
    }
    Process {
        id: gpuProc
        command: ["sh", "-c", "cat /sys/class/drm/card1/device/gpu_busy_percent; cat /sys/class/hwmon/hwmon2/temp1_input"]
        running: true
        stdout: SplitParser {
            property int ln: 0
            onRead: data => {
                var v = data.trim()
                if (ln === 0 && v !== "") root.gpuUsage = v
                if (ln === 1 && v !== "") root.gpuTemp = Math.round(parseInt(v)/1000) + ""
                ln = (ln + 1) % 2
            }
        }
    }
    Process {
        id: netProc
        command: ["sh", "-c",
            "awk 'NR>2 && $1 !~ /lo:/ {print $2\"/\"$10; exit}' /proc/net/dev; " +
            "sleep 1; " +
            "awk 'NR>2 && $1 !~ /lo:/ {print $2\"/\"$10; exit}' /proc/net/dev"
        ]
        running: true
        stdout: SplitParser {
            property int  ln:  0
            property real rx0: 0
            property real tx0: 0
            onRead: data => {
                var p = data.trim().split("/")
                if (p.length !== 2) return
                if (ln === 0) {
                    rx0 = parseFloat(p[0]) || 0
                    tx0 = parseFloat(p[1]) || 0
                } else {
                    var rx1 = parseFloat(p[0]) || 0
                    var tx1 = parseFloat(p[1]) || 0
                    root.netDown    = String(Math.max(0, rx1 - rx0))
                    root.netUp      = String(Math.max(0, tx1 - tx0))
                    root.netTotalRx = rx1
                    root.netTotalTx = tx1
                }
                ln = (ln + 1) % 2
            }
        }
    }
    Process {
        id: uptimeProc
        command: ["sh", "-c", "uptime -p | sed 's/up //'"]
        running: true
        stdout: SplitParser { onRead: data => { var v = data.trim(); if (v !== "") root.uptime = v } }
    }
    Process {
        id: kernelProc
        command: ["uname", "-r"]
        running: true
        stdout: SplitParser { onRead: data => { var v = data.trim(); if (v !== "") root.kernel = v } }
    }
    Process {
        id: hostnameProc
        command: ["hostname"]
        running: true
        stdout: SplitParser { onRead: data => { var v = data.trim(); if (v !== "") root.hostname = v } }
    }
    Process {
        id: cavaProc
        command: ["sh", "-c",
            "mkdir -p /tmp/qs-hud && " +
            "printf '[general]\\nbars=48\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nascii_max_range=100\\n' > /tmp/qs-hud/cava.cfg && " +
            "cava -p /tmp/qs-hud/cava.cfg"
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line === "") return
                var parts = line.split(";").filter(s => s !== "")
                if (parts.length > 1)
                    root.cavaBars = parts.map(s => Math.min(100, parseInt(s) || 0))
            }
        }
    }
    component HudPanel: Item {
        property string title: "PANEL"
        property string subtitle: ""
        default property alias content: innerContent.data

        // Outer border
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(11/255, 10/255, 9/255, 0.92)
            border.color: root.lineSoft
            border.width: 1
        }

        // Top sepia gradient line — matching Player.qml
        Rectangle {
            anchors.top: parent.top
            width: parent.width; height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: Qt.rgba(200/255,184/255,154/255,0.45) }
                GradientStop { position: 0.8; color: Qt.rgba(200/255,184/255,154/255,0.45) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            z: 2
        }

        // Corner accents — thicker
        Rectangle { x:0; y:0; width:16; height:2; color: root.accent }
        Rectangle { x:0; y:0; width:2; height:16; color: root.accent }
        Rectangle { anchors.right:parent.right; y:0; width:16; height:2; color: root.accent }
        Rectangle { anchors.right:parent.right; y:0; width:2; height:16; color: root.accent }
        Rectangle { x:0; anchors.bottom:parent.bottom; width:16; height:2; color: root.accent }
        Rectangle { x:0; anchors.bottom:parent.bottom; width:2; height:16; color: root.accent }
        Rectangle { anchors.right:parent.right; anchors.bottom:parent.bottom; width:16; height:2; color: root.accent }
        Rectangle { anchors.right:parent.right; anchors.bottom:parent.bottom; width:2; height:16; color: root.accent }

        // Title bar
        Item {
            id: titleBar
            width: parent.width; height: 28
            Rectangle { anchors.bottom:parent.bottom; width:parent.width; height:1; color:root.lineSoft }

            Row {
                anchors { left:parent.left; verticalCenter:parent.verticalCenter; leftMargin:12 }
                spacing: 8
                Text {
                    text: "◈"
                    font.family: "Share Tech Mono"; font.pixelSize: 10
                    color: root.accent; anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: title
                    font.family: "Share Tech Mono"; font.pixelSize: 10; font.letterSpacing: 2.5; font.weight: Font.Medium
                    color: root.inkStrong
                }
                Text {
                    visible: subtitle !== ""
                    text: "—— " + subtitle
                    font.family: "Share Tech Mono"; font.pixelSize: 9; font.letterSpacing: 1.5
                    color: root.inkSoft; anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Blink indicator
            Rectangle {
                anchors { right:parent.right; verticalCenter:parent.verticalCenter; rightMargin:12 }
                width: 5; height: 5
                color: root.tick % 2 === 0 ? root.green : "transparent"
                border.color: root.green; border.width: 1
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        // Scanline overlay
        Item {
            anchors.fill: parent
            anchors.topMargin: 28
            clip: true
            Rectangle {
                x: 0
                y: (root.scanY % parent.height)
                width: parent.width; height: 2
                color: Qt.rgba(200/255, 184/255, 154/255, 0.04)
            }
            Rectangle {
                x: 0
                y: (root.scanY + 200) % parent.height
                width: parent.width; height: 1
                color: Qt.rgba(200/255, 184/255, 154/255, 0.02)
            }
        }

        Item {
            id: innerContent
            anchors { fill:parent; topMargin:36; leftMargin:14; rightMargin:14; bottomMargin:10 }
        }
    }

    // ── Stat bar ──
    component StatBar: Item {
        property string label: "STAT"
        property real value: 0
        property string valueStr: Math.round(value) + "%"
        property string extra: ""
        height: 26

        Text {
            anchors { left:parent.left; verticalCenter:parent.verticalCenter }
            text: label
            font.family: "Share Tech Mono"; font.pixelSize: 10; font.letterSpacing: 2
            color: root.inkSoft; width: 52
        }
        // Track
        Rectangle {
            x: 56; anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 130; height: 2
            color: root.lineVsoft
        }
        // Fill
        Rectangle {
            x: 56; anchors.verticalCenter: parent.verticalCenter
            width: Math.max(2, (parent.width - 130) * Math.min(1, value / 100)); height: 2
            color: value > 85 ? root.accent : value > 60 ? root.accentGold : root.green
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }
        // Tick mark at current position
        Rectangle {
            x: 56 + Math.max(0, (parent.width - 130) * Math.min(1, value / 100) - 1)
            anchors.verticalCenter: parent.verticalCenter
            width: 2; height: 6
            color: value > 85 ? root.accent : value > 60 ? root.accentGold : root.green
            Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }
        // Value
        Text {
            anchors { right:parent.right; verticalCenter:parent.verticalCenter }
            text: valueStr + (extra !== "" ? "  " + extra : "")
            font.family: "Share Tech Mono"; font.pixelSize: 10; font.letterSpacing: 1
            color: root.inkSoft; width: 70; horizontalAlignment: Text.AlignRight
        }
    }

    property var cpuHistory: []
    property var gpuHistory: []
    property var memHistory: []
    readonly property int historyMax: 60

    function pushHistory(arr, val) {
        var a = arr.slice()
        a.push(val)
        if (a.length > historyMax) a = a.slice(a.length - historyMax)
        return a
    }

    function logColor(text) {
        if (/\[ WARN \]/.test(text)) return "#c85a3a"
        if (/\[ TASK \]/.test(text)) return "#c85a3a"
        if (/\[ SYNC \]/.test(text)) return "#4a9a6a"
        if (/\[ BOOT \]/.test(text)) return "#4a9a6a"
        if (/\[ SCAN \]/.test(text)) return root.accentGold
        return root.inkStrong
    }

    component ScrambleAnim: QtObject {
        id: anim
        property Item target: null
        property int duration: 320
        property string chars: "▸◆▪▫░▒▓█/\\|-_=+*"
        property int _elapsed: 0
        property int _step: 16
        property var _timer: Timer {
            interval: anim._step; repeat: true; running: false
            onTriggered: {
                if (!anim.target) { running = false; return }
                anim._elapsed += anim._step
                var t = Math.min(1, anim._elapsed / anim.duration)
                var finalText = anim.target.targetText
                var len = finalText.length
                var result = ""
                for (var i = 0; i < len; i++) {
                    var reveal = i / len
                    if (t > reveal + 0.15)  result += finalText[i]
                    else if (t > reveal)    result += anim.chars[Math.floor(Math.random() * anim.chars.length)]
                    else                    result += "\u00A0"
                }
                anim.target.text = result
                if (t >= 1) { anim.target.text = finalText; running = false }
            }
        }
        function start() { if (!target) return; _elapsed = 0; _timer.running = true }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors.top: true; anchors.left: true; anchors.right: true; anchors.bottom: true
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            visible: modelData.name === "DP-1"

            readonly property color curtainCol: Qt.rgba(200/255, 184/255, 154/255, 1.0)

            // ── PANEL 1: COMBAT SYSTEMS — slides in from left, hides to right ──
            Item {
                id: wipe1
                x: 120; y: 140; width: 1000; height: 420
                clip: true; visible: false

                HudPanel {
                    anchors.fill: parent
                    title: "COMBAT SYSTEMS"; subtitle: "プロセッサー負荷"
                    Column {
                        anchors.fill: parent; spacing: 2
                        StatBar { width:parent.width; label:"CPU"; value:parseFloat(root.cpuUsage)||0; valueStr:root.cpuUsage+"%"; extra:root.cpuTemp+"°C" }
                        StatBar { width:parent.width; label:"GPU"; value:parseFloat(root.gpuUsage)||0; valueStr:root.gpuUsage+"%"; extra:root.gpuTemp+"°C" }
                        StatBar { width:parent.width; label:"MEM"; value:root.ramTotal>0?(parseInt(root.ramUsage)/parseInt(root.ramTotal)*100):0; valueStr:Math.round(parseInt(root.ramUsage)/1024)+"G"; extra:Math.round(parseInt(root.ramTotal)/1024)+"G" }
                        Item { width:1; height:6 }
                        Rectangle { width:parent.width; height:1; color:root.lineVsoft }
                        Item { width:1; height:6 }
                        Row {
                            spacing:0; width:parent.width
                            // Left: blinking dot + UNIT
                            Row {
                                width: parent.parent.width / 3
                                spacing: 6
                                Rectangle {
                                    width: 5; height: 5
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: root.green
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite; running: true
                                        NumberAnimation { to: 0.2; duration: 900 }
                                        NumberAnimation { to: 1.0; duration: 900 }
                                    }
                                }
                                Text {
                                    id: unitText
                                    property string targetText: "UNIT: " + root.hostname.toUpperCase()
                                    text: targetText
                                    font.family: "Share Tech Mono"; font.pixelSize: 9; font.letterSpacing: 1.5; font.weight: Font.Medium
                                    color: root.inkSoft; opacity: 0.5
                                    anchors.verticalCenter: parent.verticalCenter
                                    ScrambleAnim { id: unitScramble; target: unitText; duration: 280 }
                                    onTargetTextChanged: unitScramble.start()
                                }
                            }
                            // Centre: SYS: ONLINE
                            Text {
                                id: sysText
                                property string targetText: "SYS: ONLINE"
                                width: parent.parent.width / 3
                                text: targetText
                                font.family: "Share Tech Mono"; font.pixelSize: 9; font.letterSpacing: 1.5; font.weight: Font.Medium
                                color: root.green; opacity: 0.6
                                horizontalAlignment: Text.AlignHCenter
                                ScrambleAnim { id: sysScramble; target: sysText; duration: 280 }
                                Component.onCompleted: sysScramble.start()
                            }
                            // Right: uptime
                            Text {
                                id: uptimeText
                                property string targetText: "UP: " + root.uptime.toUpperCase()
                                width: parent.parent.width / 3
                                text: targetText
                                font.family: "Share Tech Mono"; font.pixelSize: 9; font.letterSpacing: 1.5; font.weight: Font.Medium
                                color: root.inkSoft; opacity: 0.5
                                horizontalAlignment: Text.AlignRight
                                ScrambleAnim { id: uptimeScramble; target: uptimeText; duration: 320 }
                                onTargetTextChanged: uptimeScramble.start()
                            }
                        }

                        Item { width:1; height:10 }
                        Rectangle { width:parent.width; height:1; color:root.lineVsoft }
                        Item { width:1; height:8 }

                        // ── CPU History ──
                        Row { width:parent.width
                            Text { text:"CPU"; font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:2; font.weight:Font.Medium; color:root.inkSoft; opacity:0.5; width:36 }
                            Text { text: root.cpuHistory.length > 0 ? Math.round(root.cpuHistory[root.cpuHistory.length-1])+"%" : "0%"; font.family:"Share Tech Mono"; font.pixelSize:8; color:root.green; opacity:0.8 }
                        }
                        Canvas {
                            width:parent.width; height:26
                            property var hist: root.cpuHistory
                            onHistChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                                var d = hist; if (!d || d.length < 2) return
                                var n = d.length, H = height-6, W = width
                                var c = root.green
                                ctx.beginPath()
                                for (var i=0;i<n;i++) { var x=i/(root.historyMax-1)*W, y=3+H-(d[i]/100)*H; if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y) }
                                ctx.lineTo((n-1)/(root.historyMax-1)*W,3+H); ctx.lineTo(0,3+H); ctx.closePath()
                                var g=ctx.createLinearGradient(0,3,0,3+H); g.addColorStop(0,Qt.rgba(c.r,c.g,c.b,0.18)); g.addColorStop(1,Qt.rgba(c.r,c.g,c.b,0.02)); ctx.fillStyle=g; ctx.fill()
                                ctx.beginPath()
                                for (var j=0;j<n;j++) { var lx=j/(root.historyMax-1)*W, ly=3+H-(d[j]/100)*H; if(j===0) ctx.moveTo(lx,ly); else ctx.lineTo(lx,ly) }
                                ctx.strokeStyle=Qt.rgba(c.r,c.g,c.b,0.7); ctx.lineWidth=1.5; ctx.stroke()
                            }
                        }
                        Item { width:1; height:4 }

                        // ── GPU History ──
                        Row { width:parent.width
                            Text { text:"GPU"; font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:2; font.weight:Font.Medium; color:root.inkSoft; opacity:0.5; width:36 }
                            Text { text: root.gpuHistory.length > 0 ? Math.round(root.gpuHistory[root.gpuHistory.length-1])+"%" : "0%"; font.family:"Share Tech Mono"; font.pixelSize:8; color:root.accentGold; opacity:0.8 }
                        }
                        Canvas {
                            width:parent.width; height:26
                            property var hist: root.gpuHistory
                            onHistChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                                var d = hist; if (!d || d.length < 2) return
                                var n = d.length, H = height-6, W = width
                                var c = root.accentGold
                                ctx.beginPath()
                                for (var i=0;i<n;i++) { var x=i/(root.historyMax-1)*W, y=3+H-(d[i]/100)*H; if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y) }
                                ctx.lineTo((n-1)/(root.historyMax-1)*W,3+H); ctx.lineTo(0,3+H); ctx.closePath()
                                var g=ctx.createLinearGradient(0,3,0,3+H); g.addColorStop(0,Qt.rgba(c.r,c.g,c.b,0.18)); g.addColorStop(1,Qt.rgba(c.r,c.g,c.b,0.02)); ctx.fillStyle=g; ctx.fill()
                                ctx.beginPath()
                                for (var j=0;j<n;j++) { var lx=j/(root.historyMax-1)*W, ly=3+H-(d[j]/100)*H; if(j===0) ctx.moveTo(lx,ly); else ctx.lineTo(lx,ly) }
                                ctx.strokeStyle=Qt.rgba(c.r,c.g,c.b,0.7); ctx.lineWidth=1.5; ctx.stroke()
                            }
                        }
                        Item { width:1; height:4 }

                        // ── MEM History ──
                        Row { width:parent.width
                            Text { text:"MEM"; font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:2; font.weight:Font.Medium; color:root.inkSoft; opacity:0.5; width:36 }
                            Text { text: root.memHistory.length > 0 ? Math.round(root.memHistory[root.memHistory.length-1])+"%" : "0%"; font.family:"Share Tech Mono"; font.pixelSize:8; color:root.inkSoft; opacity:0.8 }
                        }
                        Canvas {
                            width:parent.width; height:26
                            property var hist: root.memHistory
                            onHistChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                                var d = hist; if (!d || d.length < 2) return
                                var n = d.length, H = height-6, W = width
                                var c = root.inkSoft
                                ctx.beginPath()
                                for (var i=0;i<n;i++) { var x=i/(root.historyMax-1)*W, y=3+H-(d[i]/100)*H; if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y) }
                                ctx.lineTo((n-1)/(root.historyMax-1)*W,3+H); ctx.lineTo(0,3+H); ctx.closePath()
                                var g=ctx.createLinearGradient(0,3,0,3+H); g.addColorStop(0,Qt.rgba(c.r,c.g,c.b,0.18)); g.addColorStop(1,Qt.rgba(c.r,c.g,c.b,0.02)); ctx.fillStyle=g; ctx.fill()
                                ctx.beginPath()
                                for (var j=0;j<n;j++) { var lx=j/(root.historyMax-1)*W, ly=3+H-(d[j]/100)*H; if(j===0) ctx.moveTo(lx,ly); else ctx.lineTo(lx,ly) }
                                ctx.strokeStyle=Qt.rgba(c.r,c.g,c.b,0.7); ctx.lineWidth=1.5; ctx.stroke()
                            }
                        }

                        // ── Pixel grid — combined load ──
                        Canvas {
                            id: pixelGrid
                            width: parent.width
                            property int gCols: 80
                            property int gRows: 3
                            property int gGap: 2
                            property real gSz: Math.floor((width - (gCols+1)*gGap) / gCols)
                            height: gSz * gRows + gGap * (gRows+1)
                            property real combined: {
                                var cpu = parseFloat(root.cpuUsage) || 0
                                var gpu = parseFloat(root.gpuUsage) || 0
                                var mem = root.ramTotal > 0 ? (parseInt(root.ramUsage) / parseInt(root.ramTotal) * 100) : 0
                                return (cpu + gpu + mem) / 3
                            }
                            onCombinedChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                var COLS=gCols, ROWS=gRows, GAP=gGap, sz=gSz
                                var activeCols = Math.round(combined / 100 * COLS)
                                var r, g, b
                                if (combined > 80)      { r=200/255; g=90/255;  b=58/255  }
                                else if (combined > 50) { r=200/255; g=168/255; b=74/255  }
                                else                    { r=74/255;  g=154/255; b=106/255 }
                                for (var col=0; col<COLS; col++) {
                                    for (var row=0; row<ROWS; row++) {
                                        var x = GAP + col*(sz+GAP)
                                        var y = GAP + row*(sz+GAP)
                                        if (col < activeCols) {
                                            var fade = 1.0 - (row/(ROWS-1))*0.45
                                            ctx.fillStyle = Qt.rgba(r, g, b, fade*0.85)
                                        } else {
                                            ctx.fillStyle = Qt.rgba(200/255,184/255,154/255,0.06)
                                        }
                                        ctx.fillRect(x, y, sz, sz)
                                    }
                                }
                            }
                        }

                        Item { width:1; height:8 }
                        Rectangle { width:parent.width; height:1; color:root.lineVsoft }
                        Item { width:1; height:8 }

                        // ── THREAT LEVEL ──
                        Column {
                            width: parent.width; spacing: 4
                            Row {
                                spacing: 8
                                Text {
                                    text: "THREAT LEVEL"
                                    font.family: "Share Tech Mono"; font.pixelSize: 8; font.letterSpacing: 2; font.weight: Font.Medium
                                    color: root.inkSoft; opacity: 0.5
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: {
                                        var v = parseFloat(root.cpuUsage) || 0
                                        if (v > 80) return "— CRITICAL"
                                        if (v > 50) return "— ELEVATED"
                                        return "— NOMINAL"
                                    }
                                    font.family: "Share Tech Mono"; font.pixelSize: 8; font.letterSpacing: 2; font.weight: Font.DemiBold
                                    color: {
                                        var v = parseFloat(root.cpuUsage) || 0
                                        if (v > 80) return "#c85a3a"
                                        if (v > 50) return root.accentGold
                                        return root.green
                                    }
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            Canvas {
                                id: threatCanvasA
                                width: parent.width; height: 14
                                property real cpu: parseFloat(root.cpuUsage) || 0
                                onCpuChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                                    var COLS=20, GAP=2, sz=Math.floor((width-(COLS+1)*GAP)/COLS)
                                    var active = Math.round(cpu/100*COLS)
                                    var r,g,b
                                    if(cpu>80){r=200/255;g=90/255;b=58/255}
                                    else if(cpu>50){r=200/255;g=168/255;b=74/255}
                                    else{r=74/255;g=154/255;b=106/255}
                                    for(var i=0;i<COLS;i++){
                                        var x=GAP+i*(sz+GAP), y=GAP
                                        ctx.fillStyle = i<active ? Qt.rgba(r,g,b,0.85) : Qt.rgba(200/255,184/255,154/255,0.06)
                                        ctx.fillRect(x,y,sz,sz)
                                    }
                                }
                            }
                        }

                    }
                }
                Rectangle {
                    id: curtain1
                    anchors { top:parent.top; bottom:parent.bottom }
                    x: 0; width: parent.width; color: curtainCol; z: 10
                }
            }
            SequentialAnimation {
                id: reveal1
                // Panel slides in from left, curtain wipes away right→left (x animates rightward)
                onStarted: { wipe1.x = 120-wipe1.width-2; wipe1.visible = true; curtain1.x = 0; curtain1.width = wipe1.width }
                NumberAnimation { target: wipe1;    property: "x"; from: 120-wipe1.width-2; to: 120;          duration: 460; easing.type: Easing.OutExpo }
                NumberAnimation { target: curtain1; property: "x"; from: 0;                 to: wipe1.width;   duration: 340; easing.type: Easing.OutExpo }
                onFinished: { curtain1.x = wipe1.width }
            }
            SequentialAnimation {
                id: hide1
                // Curtain sweeps right→left (x slides from right edge leftward)
                onStarted: { curtain1.x = wipe1.width; curtain1.width = wipe1.width }
                NumberAnimation { target: curtain1; property: "x"; from: wipe1.width; to: 0; duration: 180; easing.type: Easing.InOutQuart }
                NumberAnimation { target: wipe1; property: "x"; from: 120; to: 120-wipe1.width-2; duration: 380; easing.type: Easing.InExpo }
                onFinished: { wipe1.visible = false }
            }

            // ── PANEL 2: COMMS — slides in from right, hides to left ──
            Item {
                id: wipe2
                x: 1220; y: 140; width: 1220; height: 420
                clip: true; visible: false

                HudPanel {
                    anchors.fill: parent
                    title: "COMMS"; subtitle: "ネットワーク接続"

                    // ── Waveform — bottom strip, overlaps slightly upward ──
                    Canvas {
                        id: waveCanvas
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: 220
                        z: 1
                        property real phase: root.wavePhase
                        onPhaseChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            var dl = root.smoothDl
                            var ul = root.smoothUl
                            var maxB = 10000000
                            var dlAmp = (8  + (dl / maxB) * 28) * 1.08
                            var ulAmp = (6  + (ul / maxB) * 22) * 1.08
                            var dlFreq = 0.012 + (ul / maxB) * 0.018
                            var ulFreq = 0.008 + (dl / maxB) * 0.014

                            var waves = [
                                { amp: dlAmp,      freq: dlFreq,      phOff: 0,   alpha: 0.22, r:200/255, g:168/255, b:74/255  },
                                { amp: dlAmp*0.6,  freq: dlFreq*1.7,  phOff: 1.2, alpha: 0.14, r:200/255, g:168/255, b:74/255  },
                                { amp: dlAmp*0.35, freq: dlFreq*2.9,  phOff: 2.4, alpha: 0.09, r:200/255, g:168/255, b:74/255  },
                                { amp: ulAmp,      freq: ulFreq,      phOff: 0.5, alpha: 0.18, r:74/255,  g:154/255, b:106/255 },
                                { amp: ulAmp*0.55, freq: ulFreq*1.8,  phOff: 1.8, alpha: 0.11, r:74/255,  g:154/255, b:106/255 },
                                { amp: ulAmp*0.3,  freq: ulFreq*3.1,  phOff: 3.0, alpha: 0.07, r:74/255,  g:154/255, b:106/255 },
                            ]

                            for (var w = 0; w < waves.length; w++) {
                                var wv = waves[w]
                                var ph = phase + wv.phOff
                                ctx.beginPath()
                                for (var x = 0; x <= width; x += 1) {
                                    var y = height/2 + Math.sin(x * wv.freq + ph) * wv.amp
                                             + Math.sin(x * wv.freq * 0.5 + ph * 1.3) * wv.amp * 0.3
                                    if (x === 0) ctx.moveTo(x, y)
                                    else ctx.lineTo(x, y)
                                }
                                ctx.strokeStyle = Qt.rgba(wv.r, wv.g, wv.b, wv.alpha)
                                ctx.lineWidth = 1.5
                                ctx.stroke()
                            }
                        }
                    }

                    // ── Foreground content ──
                    Column {
                        anchors { fill: parent; bottomMargin: 20 }
                        spacing: 0
                        z: 2

                        // Download / Upload rates
                        Row {
                            width:parent.width; height:80; spacing:0
                            Column {
                                width:parent.parent.width/2; anchors.verticalCenter:parent.verticalCenter; spacing:5
                                Text { text:"▼  DOWNLOAD"; font.family:"Share Tech Mono"; font.pixelSize:9; font.letterSpacing:2; font.weight:Font.Medium; color:root.inkSoft; opacity:0.5 }
                                Text { text:root.fmtRate(parseInt(root.netDown)||0); font.family:"Share Tech Mono"; font.pixelSize:22; font.letterSpacing:1; font.weight:Font.DemiBold; color:root.accentGold }
                                Text { text:"TOTAL  "+root.fmt(root.netTotalRx); font.family:"Share Tech Mono"; font.pixelSize:9; font.letterSpacing:1.5; font.weight:Font.Medium; color:root.inkSoft; opacity:0.45 }
                            }
                            Column {
                                width:parent.parent.width/2; anchors.verticalCenter:parent.verticalCenter; spacing:5
                                Text { text:"▲  UPLOAD"; font.family:"Share Tech Mono"; font.pixelSize:9; font.letterSpacing:2; font.weight:Font.Medium; color:root.inkSoft; opacity:0.5 }
                                Text { text:root.fmtRate(parseInt(root.netUp)||0); font.family:"Share Tech Mono"; font.pixelSize:22; font.letterSpacing:1; font.weight:Font.DemiBold; color:root.green }
                                Text { text:"TOTAL  "+root.fmt(root.netTotalTx); font.family:"Share Tech Mono"; font.pixelSize:9; font.letterSpacing:1.5; font.weight:Font.Medium; color:root.inkSoft; opacity:0.45 }
                            }
                        }

                        Rectangle { width:parent.width; height:1; color:root.lineVsoft }
                        Item { width:1; height:6 }

                        // Network history graphs
                        Row {
                            width: parent.width; spacing: 8
                            Column {
                                width: (parent.parent.width - 8) / 2; spacing: 2
                                Row { width: parent.width
                                    Text { text:"▼"; font.family:"Share Tech Mono"; font.pixelSize:8; color:root.accentGold; opacity:0.6; width:12 }
                                    Text { text: root.downHistory.length > 0 ? root.fmtRate(root.downHistory[root.downHistory.length-1]) : "0 B/s"; font.family:"Share Tech Mono"; font.pixelSize:8; color:root.accentGold; opacity:0.7 }
                                }
                                Canvas {
                                    width: parent.width; height: 28
                                    property var hist: root.downHistory
                                    onHistChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                                        var d = hist; if (!d || d.length < 2) return
                                        var n = d.length, H = height-4, W = width
                                        var mx = Math.max.apply(null, d); if (mx < 1) mx = 1
                                        var c = root.accentGold
                                        ctx.beginPath()
                                        for (var i=0;i<n;i++) { var x=i/(root.historyMax-1)*W, y=2+H-(d[i]/mx)*H; if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y) }
                                        ctx.lineTo((n-1)/(root.historyMax-1)*W,2+H); ctx.lineTo(0,2+H); ctx.closePath()
                                        var g=ctx.createLinearGradient(0,2,0,2+H); g.addColorStop(0,Qt.rgba(c.r,c.g,c.b,0.2)); g.addColorStop(1,Qt.rgba(c.r,c.g,c.b,0.02)); ctx.fillStyle=g; ctx.fill()
                                        ctx.beginPath()
                                        for (var j=0;j<n;j++) { var lx=j/(root.historyMax-1)*W, ly=2+H-(d[j]/mx)*H; if(j===0) ctx.moveTo(lx,ly); else ctx.lineTo(lx,ly) }
                                        ctx.strokeStyle=Qt.rgba(c.r,c.g,c.b,0.7); ctx.lineWidth=1.5; ctx.stroke()
                                    }
                                }
                            }
                            Column {
                                width: (parent.parent.width - 8) / 2; spacing: 2
                                Row { width: parent.width
                                    Text { text:"▲"; font.family:"Share Tech Mono"; font.pixelSize:8; color:root.green; opacity:0.6; width:12 }
                                    Text { text: root.upHistory.length > 0 ? root.fmtRate(root.upHistory[root.upHistory.length-1]) : "0 B/s"; font.family:"Share Tech Mono"; font.pixelSize:8; color:root.green; opacity:0.7 }
                                }
                                Canvas {
                                    width: parent.width; height: 28
                                    property var hist: root.upHistory
                                    onHistChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                                        var d = hist; if (!d || d.length < 2) return
                                        var n = d.length, H = height-4, W = width
                                        var mx = Math.max.apply(null, d); if (mx < 1) mx = 1
                                        var c = root.green
                                        ctx.beginPath()
                                        for (var i=0;i<n;i++) { var x=i/(root.historyMax-1)*W, y=2+H-(d[i]/mx)*H; if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y) }
                                        ctx.lineTo((n-1)/(root.historyMax-1)*W,2+H); ctx.lineTo(0,2+H); ctx.closePath()
                                        var g=ctx.createLinearGradient(0,2,0,2+H); g.addColorStop(0,Qt.rgba(c.r,c.g,c.b,0.2)); g.addColorStop(1,Qt.rgba(c.r,c.g,c.b,0.02)); ctx.fillStyle=g; ctx.fill()
                                        ctx.beginPath()
                                        for (var j=0;j<n;j++) { var lx=j/(root.historyMax-1)*W, ly=2+H-(d[j]/mx)*H; if(j===0) ctx.moveTo(lx,ly); else ctx.lineTo(lx,ly) }
                                        ctx.strokeStyle=Qt.rgba(c.r,c.g,c.b,0.7); ctx.lineWidth=1.5; ctx.stroke()
                                    }
                                }
                            }
                        }

                        Item { width:1; height:6 }
                        Rectangle { width:parent.width; height:1; color:root.lineVsoft }
                        Item { width:1; height:6 }

                        // Connection diagnostics
                        Row {
                            width: parent.width; spacing: 0
                            Column {
                                width: parent.parent.width / 3; spacing: 3
                                Text { text:"KERNEL"; font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:2; font.weight:Font.Medium; color:root.inkSoft; opacity:0.4 }
                                Text { text:root.kernel; font.family:"Share Tech Mono"; font.pixelSize:9; font.letterSpacing:1; font.weight:Font.Medium; color:root.inkSoft; opacity:0.6; elide:Text.ElideRight; width:parent.width-8 }
                            }
                            Column {
                                width: parent.parent.width / 3; spacing: 3
                                Text { text:"SESSION"; font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:2; font.weight:Font.Medium; color:root.inkSoft; opacity:0.4 }
                                Text { text:root.uptime.toUpperCase(); font.family:"Share Tech Mono"; font.pixelSize:9; font.letterSpacing:1; font.weight:Font.Medium; color:root.inkSoft; opacity:0.6 }
                            }
                            Column {
                                width: parent.parent.width / 3; spacing: 3
                                Text { text:"UNIT"; font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:2; font.weight:Font.Medium; color:root.inkSoft; opacity:0.4 }
                                Text { text:root.hostname.toUpperCase(); font.family:"Share Tech Mono"; font.pixelSize:9; font.letterSpacing:1; font.weight:Font.Medium; color:root.inkSoft; opacity:0.6 }
                            }
                        }

                        Item { width:1; height:6 }
                        Rectangle { width:parent.width; height:1; color:root.lineVsoft }
                        Item { width:1; height:4 }

                        // Diagnostics row
                        Row {
                            width: parent.width; spacing: 0
                            Column {
                                width: parent.parent.width / 3; spacing: 3
                                Text { text:"SIGNAL"; font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:2; font.weight:Font.Medium; color:root.inkSoft; opacity:0.4 }
                                Text {
                                    text: {
                                        var b = parseInt(root.netDown) || 0
                                        if (b > 1000000) return "STRONG"
                                        if (b > 100000)  return "NOMINAL"
                                        if (b > 1000)    return "WEAK"
                                        return "IDLE"
                                    }
                                    font.family:"Share Tech Mono"; font.pixelSize:9; font.letterSpacing:1; font.weight:Font.Medium
                                    color: {
                                        var b = parseInt(root.netDown) || 0
                                        if (b > 1000000) return root.green
                                        if (b > 100000)  return root.accentGold
                                        if (b > 1000)    return "#c8a84a"
                                        return root.inkSoft
                                    }
                                    opacity: 0.6
                                }
                            }
                            Column {
                                width: parent.parent.width / 3; spacing: 3
                                Text { text:"UPLINK"; font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:2; font.weight:Font.Medium; color:root.inkSoft; opacity:0.4 }
                                Text {
                                    text: {
                                        var b = parseInt(root.netUp) || 0
                                        if (b > 500000)  return "ACTIVE"
                                        if (b > 10000)   return "STANDBY"
                                        return "SILENT"
                                    }
                                    font.family:"Share Tech Mono"; font.pixelSize:9; font.letterSpacing:1; font.weight:Font.Medium
                                    color: {
                                        var b = parseInt(root.netUp) || 0
                                        if (b > 500000) return root.green
                                        if (b > 10000)  return root.accentGold
                                        return root.inkSoft
                                    }
                                    opacity: 0.6
                                }
                            }
                            Column {
                                width: parent.parent.width / 3; spacing: 3
                                Text { text:"BUNKER LINK"; font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:2; font.weight:Font.Medium; color:root.inkSoft; opacity:0.4 }
                                Row {
                                    spacing: 5
                                    Rectangle {
                                        width:5; height:5; anchors.verticalCenter:parent.verticalCenter
                                        color: root.green
                                        SequentialAnimation on opacity {
                                            loops:Animation.Infinite; running:true
                                            NumberAnimation { to:0.2; duration:1100 }
                                            NumberAnimation { to:1.0; duration:1100 }
                                        }
                                    }
                                    Text { text:"STABLE"; font.family:"Share Tech Mono"; font.pixelSize:9; font.letterSpacing:1; font.weight:Font.Medium; color:root.green; opacity:0.8 }
                                }
                            }
                        }

                        Item { width:1; height:6 }
                        Rectangle { width:parent.width; height:1; color:root.lineVsoft }
                        Item { width:1; height:4 }
                        Item {
                            width: parent.width; height: 18; clip: true
                            Text {
                                id: commsTicker
                                text: root.tickerText + root.tickerText
                                font.family: "Share Tech Mono"; font.pixelSize: 8; font.letterSpacing: 1.5
                                color: Qt.rgba(200/255,184/255,154/255,0.2); y: 3
                                NumberAnimation on x {
                                    from: 0; to: -commsTicker.implicitWidth / 2
                                    duration: 32000; loops: Animation.Infinite; running: true
                                }
                            }
                        }
                    }

                    // ── Bottom overlay: coordinates + signal bars ──
                    Item {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: 28
                        z: 3

                        // Coordinates + timestamp — bottom left
                        Text {
                            id: coordText
                            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                            font.family: "Share Tech Mono"; font.pixelSize: 8; font.letterSpacing: 1.2
                            color: root.inkSoft; opacity: 0.35
                            property string clockStr: "--:--:--"
                            text: "35.6762° N  139.6503° E  //  UTC " + clockStr
                            Timer {
                                interval: 1000; running: true; repeat: true
                                onTriggered: {
                                    var d = new Date()
                                    var h = String(d.getUTCHours()).padStart(2,"0")
                                    var m = String(d.getUTCMinutes()).padStart(2,"0")
                                    var s = String(d.getUTCSeconds()).padStart(2,"0")
                                    coordText.clockStr = h + ":" + m + ":" + s
                                }
                            }
                        }

                        // Signal strength bars — bottom right
                        Row {
                            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                            spacing: 3
                            Repeater {
                                model: 5
                                Rectangle {
                                    width: 4
                                    height: 4 + index * 3
                                    anchors.bottom: parent.bottom
                                    property real dl: parseInt(root.netDown) || 0
                                    property int threshold: [0, 1000, 100000, 500000, 1000000][index]
                                    color: dl > threshold ? (dl > 1000000 ? root.green : root.accentGold) : root.inkSoft
                                    opacity: dl > threshold ? 0.85 : 0.15
                                    Behavior on color  { ColorAnimation  { duration: 400 } }
                                    Behavior on opacity { NumberAnimation { duration: 400 } }
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    id: curtain2
                    anchors { top:parent.top; bottom:parent.bottom; left:parent.left }
                    width: parent.width; color: curtainCol; z: 10
                }
            }
            SequentialAnimation {
                id: reveal2
                // Panel slides in from right, curtain wipes away left→right (width shrinks)
                onStarted: { wipe2.x = modelData.width+2; wipe2.visible = true; curtain2.width = wipe2.width }
                NumberAnimation { target: wipe2;    property: "x";     from: modelData.width+2; to: 1220; duration: 500; easing.type: Easing.OutExpo }
                NumberAnimation { target: curtain2; property: "width"; from: wipe2.width;        to: 0;   duration: 340; easing.type: Easing.OutExpo }
                onFinished: { curtain2.width = 0 }
            }
            SequentialAnimation {
                id: hide2
                // Curtain sweeps in left→right (x stays 0, width grows), then panel slides RIGHT off screen
                onStarted: { curtain2.x = 0; curtain2.width = 0 }
                NumberAnimation { target: curtain2; property: "width"; from: 0; to: wipe2.width; duration: 180; easing.type: Easing.InOutQuart }
                NumberAnimation { target: wipe2; property: "x"; from: 1220; to: modelData.width+2; duration: 380; easing.type: Easing.InExpo }
                onFinished: { wipe2.visible = false }
            }

            // ── PANEL 3: TACTICAL — slides in from left (staggered), hides to right ──
            Item {
                id: wipe3
                x: 120; y: modelData.height - 800; width: 580; height: 680
                clip: true; visible: false

                HudPanel {
                    anchors.fill: parent
                    title: "TACTICAL"; subtitle: "ミッションログ"
                    Column {
                        anchors.fill: parent; spacing: 0
                        Item {
                            width:parent.width; height:28; clip:true
                            Rectangle { anchors.bottom:parent.bottom; width:parent.width; height:1; color:root.lineVsoft }
                            Text {
                                id: rollingTicker
                                text: root.tickerText + root.tickerText
                                font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:1.5
                                color: Qt.rgba(200/255,184/255,154/255,0.2); y: 8
                                NumberAnimation on x { from:0; to:-rollingTicker.implicitWidth/2; duration:28000; loops:Animation.Infinite; running:true }
                            }
                        }
                        Item { width:1; height:6 }
                        Repeater {
                            model: root.missionLog.length
                            Item {
                                width: parent.width; height: 36
                                Rectangle { anchors.fill:parent; color:Qt.rgba(200/255,184/255,154/255,0.07); visible:index===root.logIndex }
                                Rectangle { anchors.left:parent.left; anchors.top:parent.top; anchors.bottom:parent.bottom; width:2; color:root.accentGold; visible:index===root.logIndex; opacity:0.8 }
                                Rectangle { anchors.bottom:parent.bottom; width:parent.width; height:1; color:root.lineVsoft }
                                Row {
                                    anchors { fill:parent; leftMargin:4 }
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 10
                                    Item {
                                        width:10; height:parent.height; anchors.verticalCenter:parent.verticalCenter
                                        Rectangle {
                                            anchors.centerIn:parent
                                            width:index===root.logIndex?6:3; height:index===root.logIndex?6:3
                                            color:index===root.logIndex?root.accentGold:root.lineSoft
                                            Behavior on width  { NumberAnimation { duration:200 } }
                                            Behavior on height { NumberAnimation { duration:200 } }
                                            Behavior on color  { ColorAnimation  { duration:200 } }
                                        }
                                    }
                                    Text {
                                        id: logText
                                        property string targetText: root.missionLog[index]
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: targetText
                                        font.family: "Share Tech Mono"
                                        font.pixelSize: index===root.logIndex ? 11 : 10
                                        font.letterSpacing: 0.8
                                        font.weight: index===root.logIndex ? Font.DemiBold : Font.Medium
                                        color: index===root.logIndex ? root.logColor(root.missionLog[index]) : root.inkSoft
                                        opacity: index===root.logIndex ? 1.0 : 0.28
                                        Behavior on opacity        { NumberAnimation { duration:300 } }
                                        Behavior on font.pixelSize { NumberAnimation { duration:200 } }
                                        ScrambleAnim { id: scramble; target: logText; duration: 300 }
                                        Connections {
                                            target: root
                                            function onLogIndexChanged() {
                                                if (root.logIndex === index) scramble.start()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Item { width: 1; height: 10 }
                    }
                }
                Rectangle {
                    id: curtain3
                    anchors { top:parent.top; bottom:parent.bottom }
                    x: 0; width: parent.width; color: curtainCol; z: 10
                }
            }
            SequentialAnimation {
                id: reveal3
                onStarted: { wipe3.x = 120-wipe3.width-2; wipe3.visible = true; curtain3.x = 0; curtain3.width = wipe3.width }
                NumberAnimation { target: wipe3;    property: "x"; from: 120-wipe3.width-2; to: 120;         duration: 460; easing.type: Easing.OutExpo }
                NumberAnimation { target: curtain3; property: "x"; from: 0;                 to: wipe3.width;  duration: 340; easing.type: Easing.OutExpo }
                onFinished: { curtain3.x = wipe3.width }
            }
            SequentialAnimation {
                id: hide3
                onStarted: { curtain3.x = wipe3.width; curtain3.width = wipe3.width }
                NumberAnimation { target: curtain3; property: "x"; from: wipe3.width; to: 0; duration: 180; easing.type: Easing.InOutQuart }
                NumberAnimation { target: wipe3; property: "x"; from: 120; to: 120-wipe3.width-2; duration: 380; easing.type: Easing.InExpo }
                onFinished: { wipe3.visible = false }
            }

            // ── PANEL 4: AUDIO — bottom right ──
            Item {
                id: wipe4
                x: 800; y: modelData.height - 800
                width: modelData.width - 920; height: 680
                clip: true; visible: false

                HudPanel {
                    anchors.fill: parent
                    title: "AUDIO"; subtitle: "スペクトラム解析"

                    Item {
                        anchors.fill: parent
                        clip: true

                        Row {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: parent.height
                            spacing: 2

                            Repeater {
                                model: root.cavaBars.length > 0 ? root.cavaBars.length : 48
                                Item {
                                    width: (parent.parent.width - 47 * 2) / 48
                                    height: parent.parent.height

                                    property real barVal: root.cavaBars.length > index ? root.cavaBars[index] : 0
                                    property real barH: Math.max(2, (parent.height * 0.5) * barVal / 100)
                                    property color barColor: barVal > 80 ? root.accent : barVal > 50 ? root.accentGold : root.inkSoft

                                    Rectangle {
                                        anchors.top: parent.top
                                        width: parent.width; height: parent.barH
                                        color: parent.barColor
                                        opacity: 0.25 + (parent.barVal / 100) * 0.75
                                        Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                                        Behavior on color  { ColorAnimation  { duration: 120 } }
                                    }
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.topMargin: parent.barH
                                        width: parent.width; height: parent.barH * 0.5
                                        color: parent.barColor
                                        opacity: (0.25 + (parent.barVal / 100) * 0.75) * 0.2
                                        Behavior on height            { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                                        Behavior on anchors.topMargin { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                                        Behavior on color             { ColorAnimation  { duration: 120 } }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width; height: 1
                            color: root.lineSoft
                        }
                    }
                }
                Rectangle {
                    id: curtain4
                    anchors { top:parent.top; bottom:parent.bottom; left:parent.left }
                    width: parent.width; color: curtainCol; z: 10
                }
            }
            SequentialAnimation {
                id: reveal4
                onStarted: { wipe4.x = modelData.width+2; wipe4.visible = true; curtain4.width = wipe4.width }
                PauseAnimation  { duration: 160 }
                NumberAnimation { target: wipe4;    property: "x";     from: modelData.width+2; to: 800;    duration: 500; easing.type: Easing.OutExpo }
                NumberAnimation { target: curtain4; property: "width"; from: wipe4.width;                to: 0;                   duration: 340; easing.type: Easing.OutExpo }
                onFinished: { curtain4.width = 0 }
            }
            SequentialAnimation {
                id: hide4
                onStarted: { curtain4.x = wipe4.width; curtain4.width = 0 }
                ParallelAnimation {
                    NumberAnimation { target: curtain4; property: "x";     from: wipe4.width; to: 0;           duration: 180; easing.type: Easing.InOutQuart }
                    NumberAnimation { target: curtain4; property: "width"; from: 0;           to: wipe4.width; duration: 180; easing.type: Easing.InOutQuart }
                }
                NumberAnimation { target: wipe4; property: "x"; from: 800; to: modelData.width+2; duration: 380; easing.type: Easing.InExpo }
                onFinished: { wipe4.visible = false }
            }

            // ── Drive animations from root.visible_ ──
            Connections {
                target: root
                function onVisible_Changed() {
                    if (root.visible_) {
                        hide1.stop(); hide2.stop(); hide3.stop(); hide4.stop()
                        reveal1.start(); reveal2.start(); reveal3.start(); reveal4.start()
                    } else {
                        reveal1.stop(); reveal2.stop(); reveal3.stop(); reveal4.stop()
                        hide1.start(); hide2.start(); hide3.start(); hide4.start()
                    }
                }
            }
            Component.onCompleted: {
                if (root.visible_) { reveal1.start(); reveal2.start(); reveal3.start(); reveal4.start() }
            }
        }
    }
}
