import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool visible_: false
    property string activeMonitor: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""

    // ── Detect active monitor ──
    Process {
        id: activeMonitorProc
        command: ["sh","-c","hyprctl cursorpos -j | python3 -c \"\nimport sys,json,subprocess\npos=json.load(sys.stdin)\nmons=json.loads(subprocess.check_output(['hyprctl','monitors','-j']))\nfor m in mons:\n    x,y=m['x'],m['y']\n    w,h=m['width'],m['height']\n    if x<=pos['x']<x+w and y<=pos['y']<y+h:\n        print(m['name'])\n        break\n\""]
        running: false
    stdout: StdioCollector {
        onStreamFinished: {
            var n = this.text.trim()
            if (n !== "") root.activeMonitor = n
            if (root.visible_) {
            spawnKitty.running = true
            resizeKitty.running = true
        }
    }
}
    }

    // ── Spawn/kill kitty ──
    Process {
        id: spawnKitty
        command: ["kitty", "--title", "scratchpad", "--class", "scratchpad"]
        running: false
    }

    Process {
        id: killKitty
        command: ["sh", "-c", "pkill -f 'kitty.*scratchpad'"]
        running: false
      }

Process {
    id: resizeKitty
    command: ["sh", "-c", 
        "sleep 0.3 && hyprctl dispatch resizewindowpixel exact $(hyprctl monitors -j | python3 -c \"import sys,json; m=[m for m in json.load(sys.stdin) if m['name']=='" + root.activeMonitor + "'][0]; print(str(m['width'])+' '+str(int(m['height']*0.4)))\"),class:scratchpad" +
        " && hyprctl dispatch movewindowpixel exact $(hyprctl monitors -j | python3 -c \"import sys,json; m=[m for m in json.load(sys.stdin) if m['name']=='" + root.activeMonitor + "'][0]; print(str(m['x'])+' '+str(int(m['y']+m['height']*0.6)))\"),class:scratchpad"
    ]
    running: false
}

function toggle() {
    root.visible_ = !root.visible_
    if (root.visible_) {
        activeMonitorProc.running = true
    } else {
        killKitty.running = true
    }
}

    IpcHandler {
        target: "scratchpad"
        function toggle(): void { root.toggle() }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData

            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.visible_ && modelData.name === root.activeMonitor
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

            readonly property bool isActive: modelData.name === root.activeMonitor
            readonly property bool shown: root.visible_ && isActive

            implicitHeight: shown ? Math.round(modelData.height * 0.4) : 0
            implicitWidth: modelData.width

            Behavior on implicitHeight {
                NumberAnimation { duration: 320; easing.type: Easing.OutExpo }
            }

            // Border on top
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: "#a89a7e"
                opacity: parent.shown ? 0.4 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Background
            Rectangle {
                anchors.fill: parent
                //color: "transparent"
                color: "#0b0a09"
                opacity: 0.96
            }

            // Corner decorations
            Text {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 8
                text: "◈ SCRATCHPAD // TERMINAL"
                font.family: "Share Tech Mono"
                font.pixelSize: 9
                font.letterSpacing: 2
                color: "#a89a7e"
                opacity: 0.4
            }

            Text {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                text: "ESC TO CLOSE"
                font.family: "Share Tech Mono"
                font.pixelSize: 9
                font.letterSpacing: 2
                color: "#a89a7e"
                opacity: 0.2
            }
        }
    }
}
