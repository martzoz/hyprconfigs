import QtQuick
import Quickshell

// ── COMBAT SYSTEMS panel content ──
// Expects a `hud` property pointing to the root HudState instance

Item {
    id: panel
    required property var hud
    anchors.fill: parent

    HudPanel {
        anchors.fill: parent
        title: "COMBAT SYSTEMS"; subtitle: "プロセッサー負荷"
        Column {
            anchors.fill: parent; spacing: 2
            StatBar { width:parent.width; label:"CPU"; value:parseFloat(hud.cpuUsage)||0; valueStr:hud.cpuUsage+"%"; extra:hud.cpuTemp+"°C" }
            StatBar { width:parent.width; label:"GPU"; value:parseFloat(hud.gpuUsage)||0; valueStr:hud.gpuUsage+"%"; extra:hud.gpuTemp+"°C" }
            StatBar { width:parent.width; label:"MEM"; value:hud.ramTotal>0?(parseInt(hud.ramUsage)/parseInt(hud.ramTotal)*100):0; valueStr:Math.round(parseInt(hud.ramUsage)/1024)+"G"; extra:Math.round(parseInt(hud.ramTotal)/1024)+"G" }
            Item { width:1; height:6 }
            Rectangle { width:parent.width; height:1; color:hud.lineVsoft }
            Item { width:1; height:6 }

            // ── Status row ──
            Row {
                spacing:0; width:parent.width
                Row {
                    width: parent.parent.width / 3; spacing: 6
                    Rectangle {
                        width: 5; height: 5; anchors.verticalCenter: parent.verticalCenter
                        color: hud.green
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite; running: true
                            NumberAnimation { to: 0.2; duration: 900 }
                            NumberAnimation { to: 1.0; duration: 900 }
                        }
                    }
                    Text {
                        id: unitText
                        property string targetText: "UNIT: " + hud.hostname.toUpperCase()
                        text: targetText
                        font.family: "Share Tech Mono"; font.pixelSize: 9; font.letterSpacing: 1.5; font.weight: Font.Medium
                        color: hud.inkSoft; opacity: 0.5
                        anchors.verticalCenter: parent.verticalCenter
                        ScrambleAnim { id: unitScramble; target: unitText; duration: 280 }
                        onTargetTextChanged: unitScramble.start()
                    }
                }
                Text {
                    id: sysText
                    property string targetText: "SYS: ONLINE"
                    width: parent.parent.width / 3
                    text: targetText
                    font.family: "Share Tech Mono"; font.pixelSize: 9; font.letterSpacing: 1.5; font.weight: Font.Medium
                    color: hud.green; opacity: 0.6
                    horizontalAlignment: Text.AlignHCenter
                    ScrambleAnim { id: sysScramble; target: sysText; duration: 280 }
                    Component.onCompleted: sysScramble.start()
                }
                Text {
                    id: uptimeText
                    property string targetText: "UP: " + hud.uptime.toUpperCase()
                    width: parent.parent.width / 3
                    text: targetText
                    font.family: "Share Tech Mono"; font.pixelSize: 9; font.letterSpacing: 1.5; font.weight: Font.Medium
                    color: hud.inkSoft; opacity: 0.5
                    horizontalAlignment: Text.AlignRight
                    ScrambleAnim { id: uptimeScramble; target: uptimeText; duration: 320 }
                    onTargetTextChanged: uptimeScramble.start()
                }
            }

            Item { width:1; height:10 }
            Rectangle { width:parent.width; height:1; color:hud.lineVsoft }
            Item { width:1; height:8 }

            // ── CPU History ──
            Row { width:parent.width
                Text { text:"CPU"; font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:2; font.weight:Font.Medium; color:hud.inkSoft; opacity:0.5; width:36 }
                Text { text: hud.cpuHistory.length > 0 ? Math.round(hud.cpuHistory[hud.cpuHistory.length-1])+"%" : "0%"; font.family:"Share Tech Mono"; font.pixelSize:8; color:hud.green; opacity:0.8 }
            }
            Canvas {
                width:parent.width; height:26
                property var hist: hud.cpuHistory
                onHistChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                    var d = hist; if (!d || d.length < 2) return
                    var n = d.length, H = height-6, W = width, c = hud.green
                    ctx.beginPath()
                    for (var i=0;i<n;i++) { var x=i/(hud.historyMax-1)*W, y=3+H-(d[i]/100)*H; if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y) }
                    ctx.lineTo((n-1)/(hud.historyMax-1)*W,3+H); ctx.lineTo(0,3+H); ctx.closePath()
                    var g=ctx.createLinearGradient(0,3,0,3+H); g.addColorStop(0,Qt.rgba(c.r,c.g,c.b,0.18)); g.addColorStop(1,Qt.rgba(c.r,c.g,c.b,0.02)); ctx.fillStyle=g; ctx.fill()
                    ctx.beginPath()
                    for (var j=0;j<n;j++) { var lx=j/(hud.historyMax-1)*W, ly=3+H-(d[j]/100)*H; if(j===0) ctx.moveTo(lx,ly); else ctx.lineTo(lx,ly) }
                    ctx.strokeStyle=Qt.rgba(c.r,c.g,c.b,0.7); ctx.lineWidth=1.5; ctx.stroke()
                }
            }
            Item { width:1; height:4 }

            // ── GPU History ──
            Row { width:parent.width
                Text { text:"GPU"; font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:2; font.weight:Font.Medium; color:hud.inkSoft; opacity:0.5; width:36 }
                Text { text: hud.gpuHistory.length > 0 ? Math.round(hud.gpuHistory[hud.gpuHistory.length-1])+"%" : "0%"; font.family:"Share Tech Mono"; font.pixelSize:8; color:hud.accentGold; opacity:0.8 }
            }
            Canvas {
                width:parent.width; height:26
                property var hist: hud.gpuHistory
                onHistChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                    var d = hist; if (!d || d.length < 2) return
                    var n = d.length, H = height-6, W = width, c = hud.accentGold
                    ctx.beginPath()
                    for (var i=0;i<n;i++) { var x=i/(hud.historyMax-1)*W, y=3+H-(d[i]/100)*H; if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y) }
                    ctx.lineTo((n-1)/(hud.historyMax-1)*W,3+H); ctx.lineTo(0,3+H); ctx.closePath()
                    var g=ctx.createLinearGradient(0,3,0,3+H); g.addColorStop(0,Qt.rgba(c.r,c.g,c.b,0.18)); g.addColorStop(1,Qt.rgba(c.r,c.g,c.b,0.02)); ctx.fillStyle=g; ctx.fill()
                    ctx.beginPath()
                    for (var j=0;j<n;j++) { var lx=j/(hud.historyMax-1)*W, ly=3+H-(d[j]/100)*H; if(j===0) ctx.moveTo(lx,ly); else ctx.lineTo(lx,ly) }
                    ctx.strokeStyle=Qt.rgba(c.r,c.g,c.b,0.7); ctx.lineWidth=1.5; ctx.stroke()
                }
            }
            Item { width:1; height:4 }

            // ── MEM History ──
            Row { width:parent.width
                Text { text:"MEM"; font.family:"Share Tech Mono"; font.pixelSize:8; font.letterSpacing:2; font.weight:Font.Medium; color:hud.inkSoft; opacity:0.5; width:36 }
                Text { text: hud.memHistory.length > 0 ? Math.round(hud.memHistory[hud.memHistory.length-1])+"%" : "0%"; font.family:"Share Tech Mono"; font.pixelSize:8; color:hud.inkSoft; opacity:0.8 }
            }
            Canvas {
                width:parent.width; height:26
                property var hist: hud.memHistory
                onHistChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                    var d = hist; if (!d || d.length < 2) return
                    var n = d.length, H = height-6, W = width, c = hud.inkSoft
                    ctx.beginPath()
                    for (var i=0;i<n;i++) { var x=i/(hud.historyMax-1)*W, y=3+H-(d[i]/100)*H; if(i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y) }
                    ctx.lineTo((n-1)/(hud.historyMax-1)*W,3+H); ctx.lineTo(0,3+H); ctx.closePath()
                    var g=ctx.createLinearGradient(0,3,0,3+H); g.addColorStop(0,Qt.rgba(c.r,c.g,c.b,0.18)); g.addColorStop(1,Qt.rgba(c.r,c.g,c.b,0.02)); ctx.fillStyle=g; ctx.fill()
                    ctx.beginPath()
                    for (var j=0;j<n;j++) { var lx=j/(hud.historyMax-1)*W, ly=3+H-(d[j]/100)*H; if(j===0) ctx.moveTo(lx,ly); else ctx.lineTo(lx,ly) }
                    ctx.strokeStyle=Qt.rgba(c.r,c.g,c.b,0.7); ctx.lineWidth=1.5; ctx.stroke()
                }
            }

            // ── Pixel grid — combined load ──
            Canvas {
                id: pixelGrid
                width: parent.width
                property int gCols: 80
                property int gRows: 3
                property int gGap:  2
                property real gSz: Math.floor((width - (gCols+1)*gGap) / gCols)
                height: gSz * gRows + gGap * (gRows+1)
                property real combined: {
                    var cpu = parseFloat(hud.cpuUsage) || 0
                    var gpu = parseFloat(hud.gpuUsage) || 0
                    var mem = hud.ramTotal > 0 ? (parseInt(hud.ramUsage) / parseInt(hud.ramTotal) * 100) : 0
                    return (cpu + gpu + mem) / 3
                }
                onCombinedChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                    var COLS=gCols, ROWS=gRows, GAP=gGap, sz=gSz
                    var activeCols = Math.round(combined/100*COLS)
                    var r,g,b
                    if(combined>80){r=200/255;g=90/255;b=58/255}
                    else if(combined>50){r=200/255;g=168/255;b=74/255}
                    else{r=74/255;g=154/255;b=106/255}
                    for(var col=0;col<COLS;col++){
                        for(var row=0;row<ROWS;row++){
                            var x=GAP+col*(sz+GAP), y=GAP+row*(sz+GAP)
                            ctx.fillStyle = col<activeCols ? Qt.rgba(r,g,b,(1.0-(row/(ROWS-1))*0.45)*0.85) : Qt.rgba(200/255,184/255,154/255,0.06)
                            ctx.fillRect(x,y,sz,sz)
                        }
                    }
                }
            }

            Item { width:1; height:8 }
            Rectangle { width:parent.width; height:1; color:hud.lineVsoft }
            Item { width:1; height:8 }

            // ── THREAT LEVEL ──
            Column {
                width: parent.width; spacing: 4
                Row {
                    spacing: 8
                    Text {
                        text: "THREAT LEVEL"
                        font.family: "Share Tech Mono"; font.pixelSize: 8; font.letterSpacing: 2; font.weight: Font.Medium
                        color: hud.inkSoft; opacity: 0.5; anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: { var v = parseFloat(hud.cpuUsage)||0; return v>80?"— CRITICAL":v>50?"— ELEVATED":"— NOMINAL" }
                        font.family: "Share Tech Mono"; font.pixelSize: 8; font.letterSpacing: 2; font.weight: Font.DemiBold
                        color: { var v = parseFloat(hud.cpuUsage)||0; return v>80?"#c85a3a":v>50?hud.accentGold:hud.green }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Canvas {
                    width: parent.width; height: 14
                    property real cpu: parseFloat(hud.cpuUsage) || 0
                    onCpuChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                        var COLS=20,GAP=2,sz=Math.floor((width-(COLS+1)*GAP)/COLS)
                        var active=Math.round(cpu/100*COLS),r,g,b
                        if(cpu>80){r=200/255;g=90/255;b=58/255}
                        else if(cpu>50){r=200/255;g=168/255;b=74/255}
                        else{r=74/255;g=154/255;b=106/255}
                        for(var i=0;i<COLS;i++){
                            ctx.fillStyle=i<active?Qt.rgba(r,g,b,0.85):Qt.rgba(200/255,184/255,154/255,0.06)
                            ctx.fillRect(GAP+i*(sz+GAP),GAP,sz,sz)
                        }
                    }
                }
            }
        }
    }
}
