import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Data as Dat

Scope {
    id: root
    property int brightness: 50

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            anchors { top: true; right: true }
            implicitWidth: 320
            implicitHeight: 190
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            focusable: false

            // Keep the fixed shell surface click-through except where controls
            // are actually present.
            mask: Region {
                Region { item: hotspot }
                Region { item: mainCircle }
                Region { item: dropPanel }
            }

            Item {
                id: corner
                anchors.fill: parent
                property bool revealed: false
                property bool expanded: false
                property bool draggingSlider: false

                function scheduleHide() {
                    hideTimer.restart()
                }

                function reveal() {
                    revealed = true
                    scheduleHide()
                    if (!readProc.running)
                        readProc.running = true
                }

                function dismiss() {
                    if (draggingSlider)
                        return
                    expanded = false
                    revealed = false
                }

                Timer {
                    id: hideTimer
                    interval: 1400
                    repeat: false
                    onTriggered: corner.dismiss()
                }

                Process {
                    id: readProc
                    command: ["sh", "-c", "brightnessctl -m | awk -F, '{gsub(/%/,\"\",$4); print $4; exit}'"]
                    stdout: SplitParser {
                        onRead: data => {
                            var v = parseInt(data.trim())
                            if (!isNaN(v))
                                root.brightness = Math.max(1, Math.min(100, v))
                        }
                    }
                }

                Process { id: setProc }

                Timer {
                    id: setTimer
                    interval: 55
                    repeat: false
                    onTriggered: {
                        setProc.command = ["brightnessctl", "-q", "set", root.brightness + "%"]
                        setProc.startDetached()
                    }
                }

                function setBrightness(v) {
                    root.brightness = Math.max(1, Math.min(100, Math.round(v)))
                    setTimer.restart()
                    scheduleHide()
                }

                Item {
                    id: hotspot
                    anchors.top: parent.top
                    anchors.right: parent.right
                    width: 82
                    height: 8

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered)
                                corner.reveal()
                        }
                    }
                }

                Item {
                    id: mainCircle
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.topMargin: corner.revealed ? 10 : -84
                    width: 74
                    height: 74

                    Behavior on anchors.topMargin {
                        SpringAnimation {
                            spring: 2.5
                            damping: 0.22
                            epsilon: 0.01
                            velocity: 1400
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Dat.Colors.background
                        border.color: Dat.Colors.color5
                        border.width: 2
                        scale: circleHover.hovered ? 1.05 : 1.0
                        Behavior on scale { SpringAnimation { spring: 3.0; damping: 0.3 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰃠"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 28
                        color: Dat.Colors.foreground
                    }

                    HoverHandler {
                        id: circleHover
                        cursorShape: Qt.PointingHandCursor
                        onHoveredChanged: {
                            if (hovered)
                                corner.scheduleHide()
                        }
                    }

                    TapHandler {
                        onTapped: {
                            corner.revealed = true
                            corner.expanded = !corner.expanded
                            corner.scheduleHide()
                            if (!readProc.running)
                                readProc.running = true
                        }
                    }
                }

                Rectangle {
                    id: dropPanel
                    anchors.top: mainCircle.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.topMargin: corner.expanded ? 8 : -12
                    width: 300
                    height: 88
                    visible: opacity > 0.01
                    opacity: corner.expanded ? 1 : 0
                    radius: 12
                    color: "#e80c0f1d"
                    border.color: Dat.Colors.color5
                    border.width: 2

                    Behavior on opacity { NumberAnimation { duration: 170 } }
                    Behavior on anchors.topMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered)
                                corner.scheduleHide()
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        text: "BRIGHTNESS  " + root.brightness + "%"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.bold: true
                        color: Dat.Colors.foreground
                    }

                    Item {
                        id: slider
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 20
                        height: 22

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 5
                            radius: 3
                            color: "#263b83"
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * (root.brightness / 100)
                            height: 6
                            radius: 3
                            color: Dat.Colors.color5
                        }

                        Rectangle {
                            width: 18
                            height: 28
                            radius: 3
                            x: Math.max(0, Math.min(slider.width - width, slider.width * (root.brightness / 100) - width / 2))
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#f7fbff"
                            border.color: Dat.Colors.color3
                            border.width: 2
                            rotation: -8
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            function apply(mouseX) {
                                corner.setBrightness((mouseX / width) * 100)
                            }

                            onPressed: mouse => {
                                corner.draggingSlider = true
                                hideTimer.stop()
                                apply(mouse.x)
                            }
                            onPositionChanged: mouse => {
                                if (pressed)
                                    apply(mouse.x)
                            }
                            onReleased: {
                                corner.draggingSlider = false
                                corner.scheduleHide()
                            }
                            onCanceled: {
                                corner.draggingSlider = false
                                corner.scheduleHide()
                            }
                        }
                    }
                }
            }
        }
    }
}
