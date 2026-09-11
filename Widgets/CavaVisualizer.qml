import QtQuick
import CavaMonitor 1.0

Item {
    id: root
    clip: false

    // Allows the wallpaper engine to stop CAVA capture entirely while the
    // desktop is covered by tiled/fullscreen windows.
    property bool active: true

    // Keep the full 50-bar resolution, but decouple expensive Canvas painting
    // from the audio callback rate. Values may arrive faster; the visual is
    // repainted at most ~30 Hz.
    property bool paintPending: false
    property bool hasAudioActivity: false
    property real silenceThreshold: 0.002

    CavaMonitor {
        id: cava
        bars: 50
        active: root.active
    }

    function valuesHaveActivity(values) {
        if (!values || values.length === 0)
            return false

        for (var i = 0; i < values.length; ++i) {
            if (Math.abs(values[i]) > root.silenceThreshold)
                return true
        }
        return false
    }

    Connections {
        target: cava
        function onValuesChanged() {
            if (!root.active)
                return

            var nowActive = root.valuesHaveActivity(cava.values)

            // When audio drops to silence, request exactly one final repaint to
            // clear the old waveform, then stop repainting until audio returns.
            if (root.hasAudioActivity && !nowActive)
                root.paintPending = true
            else if (nowActive)
                root.paintPending = true

            root.hasAudioActivity = nowActive
        }
    }

    Timer {
        id: paintTicker
        interval: 33
        repeat: true
        running: root.active
        onTriggered: {
            if (!root.paintPending)
                return

            root.paintPending = false
            canvas.requestPaint()
        }
    }

    onActiveChanged: {
        if (!active) {
            hasAudioActivity = false
            paintPending = false
        } else {
            // Refresh once after CAVA resumes so the canvas state catches up.
            paintPending = true
        }
    }

    Canvas {
        id: canvas
        clip: false
        anchors.fill: parent
        renderStrategy: Canvas.Threaded

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            if (!root.active || !root.hasAudioActivity)
                return

            drawMountainWave(ctx, cava.values, true)
            drawMountainWave(ctx, cava.values, false)
        }

        function drawMountainWave(ctx, data, isShadow) {
            if (!data || data.length < 2)
                return

            var hPad = width * 0.03
            var drawW = width - 2 * hPad
            var barWidth = drawW / (data.length - 1)

            function xOf(i) {
                return hPad + i * barWidth
            }

            var baseline = height

            function barTopY(i) {
                return baseline - data[i] * baseline * 0.9
            }

            var gradient = ctx.createLinearGradient(0, 0, width, 0)
            gradient.addColorStop(0.0, Qt.rgba(1, 1, 1, 0.12))
            gradient.addColorStop(0.3, Qt.rgba(1, 1, 1, 0.25))
            gradient.addColorStop(0.5, Qt.rgba(1, 1, 1, 0.30))
            gradient.addColorStop(0.7, Qt.rgba(1, 1, 1, 0.25))
            gradient.addColorStop(1.0, Qt.rgba(1, 1, 1, 0.12))

            ctx.beginPath()
            if (isShadow) {
                ctx.globalAlpha = 0.3
                ctx.save()
                ctx.translate(0, -10)
                ctx.scale(1.02, 1.05)
            } else {
                ctx.globalAlpha = 1.0
            }

            ctx.fillStyle = gradient
            ctx.moveTo(xOf(0), baseline)
            ctx.lineTo(xOf(0), barTopY(0))

            for (var i = 0; i < data.length - 1; i++) {
                var xC = xOf(i), yC = barTopY(i)
                var xN = xOf(i + 1), yN = barTopY(i + 1)
                ctx.quadraticCurveTo(xC, yC, (xC + xN) / 2, (yC + yN) / 2)
            }

            var last = data.length - 1
            ctx.lineTo(xOf(last), barTopY(last))
            ctx.lineTo(xOf(last), baseline)
            ctx.lineTo(xOf(0), baseline)
            ctx.closePath()
            ctx.fill()

            if (isShadow)
                ctx.restore()
        }
    }
}
