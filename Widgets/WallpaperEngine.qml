import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Data as Dat

WlrLayershell {
    id: root

    required property ShellScreen modelData
    property real mouseOffsetX: 0.0
    property real mouseOffsetY: 0.0
    property double wallpaperStartMs: Date.now()
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    layer: WlrLayer.Bottom
    namespace: "wallpaper.engine"
    screen: modelData

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Drive only the animated wallpaper uniforms at roughly 60 Hz instead of
    // tying three perpetual NumberAnimations to the display refresh rate.
    // Hyprland, applications, cursor motion, etc. remain free to present at the
    // monitor's native refresh rate; this timer only changes wallpaper shader
    // time properties. Date.now() keeps animation speed stable if a tick is late.
    Timer {
        id: wallpaperTicker
        interval: 16
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            var elapsedSeconds = (Date.now() - root.wallpaperStartMs) / 1000.0
            s0_bg_clouds.time = (elapsedSeconds * (10.0 / 800.0)) % 10.0
            s0_bg_stars.time = (elapsedSeconds * (1000.0 / 500.0)) % 1000.0
            s1_bars_motion.time = (elapsedSeconds * (10000.0 / 10000.0)) % 10000.0
        }
    }

    Image {
        id: bgRaw
        source: Qt.resolvedUrl("../Assets/p3r imgs/bg.png")
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        visible: false
    }

    Image {
        id: cloudMaskRaw
        source: Qt.resolvedUrl("../Assets/Depth masks/cloudmask.png")
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        visible: false
    }

    Image {
        id: normalMapRipple
        source: Qt.resolvedUrl("../Assets/Depth masks/normalmaps/waterripplenormal.png")
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        visible: false
    }

    Image {
        id: barsRaw
        source: Qt.resolvedUrl("../Assets/p3r imgs/bars.png")
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        visible: false
    }

    Image {
        id: depthMapRaw
        source: Qt.resolvedUrl("../Assets/Depth masks/makotodepth.png")
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        visible: false
    }

    // ── Stage 0a: Ripple ──
    ShaderEffect {
        id: s0_bg_clouds
        anchors.fill: parent
        visible: true

        property var source: bgRaw
        property var normalMap: normalMapRipple
        property var depthMask: cloudMaskRaw
        property real time: 0
        property real flowStrength: 0.006
        property real speed: 2.5
        property real frequency: 1.0

        vertexShader: Qt.resolvedUrl("../Assets/shaders/ripple/ripple.vert.qsb")
        fragmentShader: Qt.resolvedUrl("../Assets/shaders/ripple/ripple.frag.qsb")
    }

    // Ripple has to be materialized once because the Stars/Rain shader samples
    // the result of another ShaderEffect. Keep this required pass.
    ShaderEffectSource {
        id: s0_clouds_out
        sourceItem: s0_bg_clouds
        anchors.fill: parent
        visible: false
        hideSource: true
        live: true
    }

    // ── Stage 1: Composite ──
    // The Stars/Rain ShaderEffect now lives directly inside the composite.
    // Previously it was rendered into an extra full-screen ShaderEffectSource
    // (s0_bg_out) only to be drawn immediately into this composite. Removing
    // that redundant FBO keeps the same visual order while saving one live
    // full-resolution offscreen pass and its backing texture.
    Item {
        id: s1_composite
        anchors.fill: parent
        visible: false

        ShaderEffect {
            id: s0_bg_stars
            anchors.fill: parent

            property var source: s0_clouds_out
            property real time: 0
            property real strength: 50
            property real speed: 5.5
            property real frequency: 10.0

            vertexShader: Qt.resolvedUrl("../Assets/shaders/stars/stars.vert.qsb")
            fragmentShader: Qt.resolvedUrl("../Assets/shaders/stars/stars.frag.qsb")
        }

        ShaderEffect {
            id: s1_bars_motion
            anchors.fill: parent

            property var source: barsRaw
            property real time: 0
            property real speed: 1

            vertexShader: Qt.resolvedUrl("../Assets/shaders/motion/motion.vert.qsb")
            fragmentShader: Qt.resolvedUrl("../Assets/shaders/motion/motion.frag.qsb")
        }

        CavaVisualizer {
            id: s1_cava
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: 0
            }
            height: 555
        }

        Image {
            id: s1_fg
            source: Qt.resolvedUrl("../Assets/p3r imgs/fg.png")
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: true
        }
    }

    // Composite output is still required because the final Parallax shader
    // samples the complete Stars/Bars/CAVA/foreground scene as one texture.
    ShaderEffectSource {
        id: s1_out
        sourceItem: s1_composite
        anchors.fill: parent
        visible: false
        hideSource: true
        live: true
    }

    // ── Stage 2: Parallax ──
    ShaderEffect {
        id: s2_parallax
        anchors.fill: parent
        visible: true

        property var source: s1_out
        property real offsetX: root.mouseOffsetX
        property real offsetY: root.mouseOffsetY
        property real parallaxStrength: 0.03
        property real aspectRatio: width / height
        property var depthMap: depthMapRaw

        vertexShader: Qt.resolvedUrl("../Assets/shaders/parallax/parallax.vert.qsb")
        fragmentShader: Qt.resolvedUrl("../Assets/shaders/parallax/parallax.frag.qsb")
    }

    // ── Mouse tracking ──
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: mouse => {
            root.mouseOffsetX = (mouse.x / width - 0.5) * 2.0;
            root.mouseOffsetY = (mouse.y / height - 0.5) * 2.0;
        }
    }
}
