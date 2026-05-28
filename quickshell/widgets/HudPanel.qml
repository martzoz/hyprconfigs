import QtQuick
import Quickshell

Item {
    id: hudPanel
    property string title:    "PANEL"
    property string subtitle: ""
    default property alias content: innerContent.data

    // Allow override from parent (for Player.qml which has its own root scope)
    property int  tickOverride:  -1
    property real scanYOverride: -1
    property int  _tick:  tickOverride  >= 0 ? tickOverride  : (typeof root !== "undefined" ? root.tick  : 0)
    property real _scanY: scanYOverride >= 0 ? scanYOverride : (typeof root !== "undefined" ? root.scanY : 0)

    // Shared palette — read from root ShellRoot
    readonly property color _accent:    Qt.rgba(200/255,184/255,154/255,1.0)
    readonly property color _inkStrong: "#e8d8b8"
    readonly property color _inkSoft:   "#8a7a62"
    readonly property color _lineSoft:  Qt.rgba(200/255,184/255,154/255,0.18)
    readonly property color _green:     "#4a9a6a"

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(11/255,10/255,9/255,0.92)
        border.color: _lineSoft; border.width: 1
    }
    Rectangle {
        anchors.top: parent.top; width: parent.width; height: 1; z: 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position:0.0; color:"transparent" }
            GradientStop { position:0.2; color:Qt.rgba(200/255,184/255,154/255,0.45) }
            GradientStop { position:0.8; color:Qt.rgba(200/255,184/255,154/255,0.45) }
            GradientStop { position:1.0; color:"transparent" }
        }
    }
    Rectangle { x:0;y:0;width:16;height:2;color:_accent }
    Rectangle { x:0;y:0;width:2;height:16;color:_accent }
    Rectangle { anchors.right:parent.right;y:0;width:16;height:2;color:_accent }
    Rectangle { anchors.right:parent.right;y:0;width:2;height:16;color:_accent }
    Rectangle { x:0;anchors.bottom:parent.bottom;width:16;height:2;color:_accent }
    Rectangle { x:0;anchors.bottom:parent.bottom;width:2;height:16;color:_accent }
    Rectangle { anchors.right:parent.right;anchors.bottom:parent.bottom;width:16;height:2;color:_accent }
    Rectangle { anchors.right:parent.right;anchors.bottom:parent.bottom;width:2;height:16;color:_accent }

    Item {
        id: titleBar; width:parent.width; height:28
        Rectangle { anchors.bottom:parent.bottom;width:parent.width;height:1;color:_lineSoft }
        Row {
            anchors { left:parent.left; verticalCenter:parent.verticalCenter; leftMargin:12 }
            spacing: 8
            Text { text:"◈"; font.family:"Share Tech Mono"; font.pixelSize:10; color:_accent; anchors.verticalCenter:parent.verticalCenter }
            Text { text:title; font.family:"Share Tech Mono"; font.pixelSize:10; font.letterSpacing:2.5; font.weight:Font.Medium; color:_inkStrong }
            Text { visible:subtitle!==""; text:"—— "+subtitle; font.family:"Share Tech Mono"; font.pixelSize:9; font.letterSpacing:1.5; color:_inkSoft; anchors.verticalCenter:parent.verticalCenter }
        }
        // Blink dot — reads from root
        Rectangle {
            anchors { right:parent.right; verticalCenter:parent.verticalCenter; rightMargin:12 }
            width:5; height:5
            color: hudPanel._tick%2===0 ? _green : "transparent"
            border.color:_green; border.width:1
            Behavior on color { ColorAnimation { duration:200 } }
        }
    }

    // Scanline overlay
    Item {
        anchors.fill:parent; anchors.topMargin:28; clip:true
        Rectangle { x:0;y:hudPanel._scanY%parent.height;width:parent.width;height:2;color:Qt.rgba(200/255,184/255,154/255,0.04) }
        Rectangle { x:0;y:(hudPanel._scanY+200)%parent.height;width:parent.width;height:1;color:Qt.rgba(200/255,184/255,154/255,0.02) }
    }

    Item {
        id: innerContent
        anchors { fill:parent; topMargin:36; leftMargin:14; rightMargin:14; bottomMargin:10 }
    }
}
