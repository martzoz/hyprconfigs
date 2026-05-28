import QtQuick

Item {
    property string label:    "STAT"
    property real   value:    0
    property string valueStr: Math.round(value)+"%"
    property string extra:    ""
    height: 26

    Text {
        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
        text: label; font.family:"Share Tech Mono"; font.pixelSize:10; font.letterSpacing:2
        color: root.inkSoft; width: 52
    }
    Rectangle {
        x:56; anchors.verticalCenter:parent.verticalCenter
        width:parent.width-130; height:2; color:root.lineVsoft
    }
    Rectangle {
        x:56; anchors.verticalCenter:parent.verticalCenter
        width:Math.max(2,(parent.width-130)*Math.min(1,value/100)); height:2
        color:value>85?root.accent:value>60?root.accentGold:root.green
        Behavior on width { NumberAnimation { duration:600; easing.type:Easing.OutCubic } }
    }
    Rectangle {
        x:56+Math.max(0,(parent.width-130)*Math.min(1,value/100)-1)
        anchors.verticalCenter:parent.verticalCenter
        width:2; height:6
        color:value>85?root.accent:value>60?root.accentGold:root.green
        Behavior on x { NumberAnimation { duration:600; easing.type:Easing.OutCubic } }
    }
    Text {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        text: valueStr+(extra!==""?"  "+extra:"")
        font.family:"Share Tech Mono"; font.pixelSize:10; font.letterSpacing:1
        color:root.inkSoft; width:70; horizontalAlignment:Text.AlignRight
    }
}
