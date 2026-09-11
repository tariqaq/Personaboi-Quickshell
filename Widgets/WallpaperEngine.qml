import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Data as Dat

WlrLayershell {
    id: root

    required property ShellScreen modelData
    property real mouseOffsetX: 0.0
    property real mouseOffsetY: 0.0
    property real pendingMouseOffsetX: 0.0
    property real pendingMouseOffsetY: 0.0
    property double wallpaperStartMs: Date.now()
    property bool wallpaperCovered: false

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

    updatesEnabled: !root.wallpaperCovered

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            coverageDebounce.restart()
        }
    }

    Timer {
        id: coverageDebounce
        interval: 120
        repeat: false
        onTriggered: root.refreshCoverage()
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshCoverage()
    }

    Process {
        id: coverageProc
        command: [
            "sh", "-c",
            "mon=\"$1\"; mjson=\"$(hyprctl monitors -j 2>/dev/null)\" || { echo 0; exit; }; ws=\"$(printf '%s' \"$mjson\" | jq -r --arg mon \"$mon\" '.[] | select(.name == $mon) | .activeWorkspace.id' | head -n1)\"; sws=\"$(printf '%s' \"$mjson\" | jq -r --arg mon \"$mon\" '.[] | select(.name == $mon) | (.specialWorkspace.id // 0)' | head -n1)\"; [ -n \"$ws\" ] && [ \"$ws\" != null ] || { echo 0; exit; }; [ -n \"$sws\" ] && [ \"$sws\" != null ] || sws=0; hyprctl clients -j 2>/dev/null | jq -r --argjson ws \"$ws\" --argjson sws \"$sws\" '[.[] | select(.workspace.id == $ws or ($sws != 0 and .workspace.id == $sws))] as $c | if ($c | length) == 0 then 0 elif (($c | map(select(.floating == true)) | length) > 0) then 0 else 1 end'",
            "personaboi-coverage", root.modelData.name
        ]
        stdout: SplitParser {
            onRead: data => {
                var value = data.trim()
                if (value === "0" || value === "1")
                    root.wallpaperCovered = value === "1"
            }
        }
    }

    function refreshCoverage() {
        if (!coverageProc.running)
            coverageProc.running = true
    }

    // One 60 Hz cadence owns both animated shader time and parallax state.
    // Raw pointer motion only updates pending values; the expensive final
    // parallax ShaderEffect is dirtied at most once per wallpaper tick.
    Timer {
        id: wallpaperTicker
        interval: 16
        repeat: true
        running: !root.wallpaperCovered
        triggeredOnStart: true
        onTriggered: {
            var elapsedSeconds = (Date.now() - root.wallpaperStartMs) / 1000.0
            s0_bg_clouds.time = (elapsedSeconds * (10.0 / 800.0)) % 10.0
            s0_bg_stars.time = (elapsedSeconds * (1000.0 / 500.0)) % 1000.0
            s1_bars_motion.time = (elapsedSeconds * (10000.0 / 10000.0)) % 10000.0

            if (root.mouseOffsetX !== root.pendingMouseOffsetX)
                root.mouseOffsetX = root.pendingMouseOffsetX
            if (root.mouseOffsetY !== root.pendingMouseOffsetY)
                root.mouseOffsetY = root.pendingMouseOffsetY
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

    // Required native-resolution intermediate texture for Stars/Rain.
    ShaderEffectSource {
        id: s0_clouds_out
        sourceItem: s0_bg_clouds
        anchors.fill: parent
        visible: false
        hideSource: true
        live: true
    }

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
            active: !root.wallpaperCovered
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

    // Required native-resolution composite texture for final Parallax.
    ShaderEffectSource {
        id: s1_out
        sourceItem: s1_composite
        anchors.fill: parent
        visible: false
        hideSource: true
        live: true
    }

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

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: mouse => {
            root.pendingMouseOffsetX = (mouse.x / width - 0.5) * 2.0
            root.pendingMouseOffsetY = (mouse.y / height - 0.5) * 2.0
        }
    }
}
