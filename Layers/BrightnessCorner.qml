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
            implicitWidth: corner.expanded ? 320 : (corner.shellVisible ? 110 : 82)
            implicitHeight: corner.expanded ? 190 : (corner.shellVisible ? 105 : 7)
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            focusable: false

            Item {
                id: corner
                anchors.fill: parent
                property bool hovered: false
                property bool expanded: false
                // Keep the shell window large enough while the circle animates
                // out. Collapsing the PanelWindow immediately clips the circle
                // and makes it look like it vanished instead of sliding away.
                property bool shellVisible: false

                Timer {
                    id: autoHideTimer
                    interval: 900
                    repeat: false
                    onTriggered: {
                        if (!corner.expanded) {
                            corner.hovered = false
                            collapseTimer.restart()
                        }
                    }
                }

                Timer {
                    id: collapseTimer
                    interval: 520
                    repeat: false
                    onTriggered: {
                        if (!corner.hovered && !corner.expanded)
                            corner.shellVisible = false
                    }
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

                function showCorner() {
                    corner.shellVisible = true
                    corner.hovered = true
                    collapseTimer.stop()
                    autoHideTimer.stop()
                }

                function setBrightness(v) {
                    root.brightness = Math.max(1, Math.min(100, Math.round(v)))
                    setTimer.restart()
                }

                Item {
                    id: hotspot
                    anchors.top: parent.top
                    anchors.right: parent.right
                    width: 82
                    height: 7
                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered) {
                                corner.showCorner()
                                if (!readProc.running)
                                    readProc.running = true
                            } else if (!corner.expanded) {
                                autoHideTimer.restart()
                            }
                        }
                    }
                }

                Item {
                    id: mainCircle
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 10
                    anchors.rightMargin: 10
                    width: 74
                    height: 74
                    visible: corner.shellVisible
                    y: corner.hovered || corner.expanded ? 0 : -110

                    Behavior on y {
                        SpringAnimation { spring: 2.5; damping: 0.22; epsilon: 0.01; velocity: 1400 }
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
                            if (hovered) {
                                corner.showCorner()
                            } else if (!corner.expanded) {
                                autoHideTimer.restart()
                            }
                        }
                    }

                    TapHandler {
                        onTapped: {
                            corner.expanded = !corner.expanded
                            corner.showCorner()
                            if (corner.expanded) {
                                if (!readProc.running)
                                    readProc.running = true
                            } else {
                                autoHideTimer.restart()
                            }
                        }
                    }
                }

                Rectangle {
                    id: dropPanel
                    anchors.top: mainCircle.bottom
                    anchors.topMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    width: 300
                    height: 88
                    visible: corner.expanded
                    opacity: corner.expanded ? 1 : 0
                    radius: 12
                    color: "#e80c0f1d"
                    border.color: Dat.Colors.color5
                    border.width: 2

                    Behavior on opacity { NumberAnimation { duration: 160 } }

                    Text {
                        id: titleText
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
                            onPressed: mouse => apply(mouse.x)
                            onPositionChanged: mouse => { if (pressed) apply(mouse.x) }
                        }
                    }
                }

                HoverHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onHoveredChanged: {
                        if (hovered) {
                            corner.showCorner()
                        } else if (!corner.expanded) {
                            autoHideTimer.restart()
                        }
                    }
                }
            }
        }
    }
}
