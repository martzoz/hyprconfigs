import QtQuick
import Quickshell
import Quickshell.Io

// ── TACTICAL panel content ──
Item {
    id: panel
    required property var hud
    anchors.fill: parent

    // ── Diagnostic state ──
    property var diagStatus: ({ "MULLVAD": "WARN", "MINECRAFT": "WARN" })

    function setStatus(key, val) {
        var d = Object.assign({}, diagStatus)
        d[key] = val
        diagStatus = d
    }

    function statusColor(s) {
        if (s === "SYNC") return hud.green
        if (s === "SCAN") return hud.accentGold
        return "#c85a3a"
    }

    function statusTag(s) {
        if (s === "SYNC") return "[ SYNC ]"
        if (s === "SCAN") return "[ SCAN ]"
        return "[ WARN ]"
    }

    // ── Diagnostic entries (declarative, easy to extend) ──
    readonly property var diagEntries: [
        { key: "MULLVAD",   label: "MULLVAD VPN",  subtitle: "mullvad-daemon" },
        { key: "MINECRAFT", label: "MINECRAFT SRV", subtitle: "tmux:minecraft" },
    ]

    // ── Processes ──
    Process {
        id: mullvadProc
        command: ["sh", "-c", "mullvad status | grep -c Connected"]
        stdout: SplitParser {
            onRead: data => {
                var v = data.trim()
                if (v === "1") panel.setStatus("MULLVAD", "SYNC")
                else           panel.setStatus("MULLVAD", "WARN")
            }
        }
    }

    Process {
        id: minecraftProc
        command: ["sh", "-c", "tmux has-session -t minecraft 2>/dev/null && echo 1 || echo 0"]
        stdout: SplitParser {
            onRead: data => {
                var v = data.trim()
                if (v === "0") panel.setStatus("MINECRAFT", "WARN")
                else           minecraftScanProc.running = true
            }
        }
    }

    Process {
        id: minecraftScanProc
        command: ["sh", "-c", "tmux capture-pane -t minecraft -p | grep -c Done"]
        stdout: SplitParser {
            onRead: data => {
                var v = data.trim()
                if (parseInt(v) > 0) panel.setStatus("MINECRAFT", "SYNC")
                else                 panel.setStatus("MINECRAFT", "SCAN")
            }
        }
    }

    // ── Polling timer (every 5s) ──
    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: { mullvadProc.running = true; minecraftProc.running = true }
    }

    Component.onCompleted: { mullvadProc.running = true; minecraftProc.running = true }

    // ── Ticker text — reflects live panel + service state ──
    // Status words padded to equal length per segment to prevent ticker jitter
    readonly property string tacticalTickerText: {
        var parts = []
        parts.push(hud.showCombat   ? "COMBAT SYSTEMS — ACTIVE " : "COMBAT SYSTEMS — OFFLINE")
        parts.push(hud.showComms    ? "COMMS — ACTIVE "           : "COMMS — OFFLINE")
        parts.push(hud.showTactical ? "TACTICAL — ACTIVE "        : "TACTICAL — OFFLINE")
        parts.push(hud.showAudio    ? "AUDIO — ACTIVE "           : "AUDIO — OFFLINE")
        parts.push(diagStatus["MULLVAD"]   === "SYNC" ? "MULLVAD — CONNECTED   " : "MULLVAD — DISCONNECTED")
        parts.push(diagStatus["MINECRAFT"] === "SYNC" ? "MINECRAFT — ONLINE  "
                 : diagStatus["MINECRAFT"] === "SCAN" ? "MINECRAFT — BOOTING "   : "MINECRAFT — OFFLINE")
        return parts.join("  //  ") + "  //  "
    }

    HudPanel {
        anchors.fill: parent
        title: "TACTICAL"; subtitle: "システム診断"

        Column {
            anchors.fill: parent; spacing: 0

            // ── Ticker with independent shimmers ──
            Item {
                width: parent.width; height: 28; clip: true

                // Scanline bands — independent animations, never reset visibly
                property real shimmer1: 0
                property real shimmer2: 0
                property real shimmer3: 0
                property real shimmer4: 0
                property real shimmer5: 0
                NumberAnimation on shimmer1 { from: -20; to: width+20; duration: 6000;  loops: Animation.Infinite; running: true; easing.type: Easing.Linear }
                NumberAnimation on shimmer2 { from: -20; to: width+20; duration: 9500;  loops: Animation.Infinite; running: true; easing.type: Easing.Linear }
                NumberAnimation on shimmer3 { from: -20; to: width+20; duration: 14000; loops: Animation.Infinite; running: true; easing.type: Easing.Linear }
                NumberAnimation on shimmer4 { from: -20; to: width+20; duration: 19000; loops: Animation.Infinite; running: true; easing.type: Easing.Linear }
                NumberAnimation on shimmer5 { from: -20; to: width+20; duration: 24000; loops: Animation.Infinite; running: true; easing.type: Easing.Linear }

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: hud.lineVsoft }

                Text {
                    id: rollingTicker
                    text: panel.tacticalTickerText + panel.tacticalTickerText
                    font.family: "Share Tech Mono"; font.pixelSize: 8; font.letterSpacing: 1.5
                    color: Qt.rgba(200/255,184/255,154/255,0.2); y: 8
                    NumberAnimation on x {
                        id: tacticalTickerAnim
                        from: 0; to: -rollingTicker.implicitWidth/2
                        duration: 28000; loops: Animation.Infinite; running: true
                        easing.type: Easing.Linear
                    }
                    Component.onCompleted: tacticalTickerAnim.restart()
                }

                Canvas {
                    anchors.fill: parent
                    property real s1: parent.shimmer1
                    property real s2: parent.shimmer2
                    property real s3: parent.shimmer3
                    property real s4: parent.shimmer4
                    property real s5: parent.shimmer5
                    onS1Changed: requestPaint()
                    onS2Changed: requestPaint()
                    onS3Changed: requestPaint()
                    onS4Changed: requestPaint()
                    onS5Changed: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var bands = [s1, s2, s3, s4, s5]
                        var alphas    = [0.12, 0.09, 0.11, 0.07, 0.09]
                        var halfWidths = [8,    6,    10,   5,    7   ]
                        for (var i = 0; i < bands.length; i++) {
                            var cx = bands[i]
                            var hw = halfWidths[i]
                            var grd = ctx.createLinearGradient(cx - hw, 0, cx + hw, 0)
                            grd.addColorStop(0.0, Qt.rgba(200/255,184/255,154/255,0.0))
                            grd.addColorStop(0.5, Qt.rgba(200/255,184/255,154/255,alphas[i]))
                            grd.addColorStop(1.0, Qt.rgba(200/255,184/255,154/255,0.0))
                            ctx.fillStyle = grd
                            ctx.fillRect(0, 0, width, height)
                        }
                    }
                }
            }

            Item { width: 1; height: 8 }

            // ── Section header ──
            Row {
                width: parent.width; leftPadding: 4
                Text {
                    text: "SERVICE"; font.family: "Share Tech Mono"; font.pixelSize: 8
                    font.letterSpacing: 2; color: hud.inkSoft; opacity: 0.4
                    width: parent.parent.width * 0.55
                }
                Text {
                    text: "STATUS"; font.family: "Share Tech Mono"; font.pixelSize: 8
                    font.letterSpacing: 2; color: hud.inkSoft; opacity: 0.4
                }
            }

            Item { width: 1; height: 4 }
            Rectangle { width: parent.width; height: 1; color: hud.lineVsoft }

            // ── Diagnostic rows ──
            Repeater {
                model: panel.diagEntries
                Item {
                    width: parent.width; height: 52
                    property string status: panel.diagStatus[modelData.key] || "WARN"

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(200/255,184/255,154/255,0.04)
                        visible: status === "SYNC"
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                        width: 2; color: panel.statusColor(status); opacity: 0.8
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: hud.lineVsoft }

                    Row {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                        spacing: 0

                        Column {
                            width: parent.width * 0.55
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text {
                                text: modelData.label
                                font.family: "Share Tech Mono"; font.pixelSize: 11
                                font.letterSpacing: 1; font.weight: Font.DemiBold
                                color: hud.inkStrong
                            }
                            Text {
                                text: modelData.subtitle
                                font.family: "Share Tech Mono"; font.pixelSize: 8
                                font.letterSpacing: 1; color: hud.inkSoft; opacity: 0.5
                            }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            Rectangle {
                                width: 5; height: 5
                                anchors.verticalCenter: parent.verticalCenter
                                color: panel.statusColor(status)
                                Behavior on color { ColorAnimation { duration: 400 } }
                                opacity: status === "SYNC" ? 0.9 : 0.5
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite; running: status === "SCAN"
                                    NumberAnimation { to: 0.2; duration: 800 }
                                    NumberAnimation { to: 1.0; duration: 800 }
                                }
                            }
                            Text {
                                text: panel.statusTag(status)
                                font.family: "Share Tech Mono"; font.pixelSize: 10
                                font.letterSpacing: 1; font.weight: Font.Medium
                                color: panel.statusColor(status)
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 10 }
        }
    }
}
