import QtQuick

QtObject {
    id: anim
    property Item   target:   null
    property int    duration: 320
    property string chars:    "▸◆▪▫░▒▓█/\\|-_=+*"
    property int    _elapsed: 0
    property int    _step:    16
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
