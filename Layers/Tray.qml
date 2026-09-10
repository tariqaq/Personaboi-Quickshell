import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import QtQuick

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: trayWindow

            required property var modelData
            screen: modelData

            anchors {
                top: true
                right: true
            }

            implicitWidth: trayRow.implicitWidth + 20
            implicitHeight: SystemTray.items.values.length > 0 ? 42 : 1

            color: "transparent"
            visible: SystemTray.items.values.length > 0
            focusable: false

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "persona.tray"

            margins {
                top: 100
                right: 18
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "#990b1f55"
                border.width: 1
                border.color: "#66ffffff"

                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 8

                    Repeater {
                        model: SystemTray.items

                        delegate: Item {
                            id: trayItem

                            required property var modelData

                            width: 26
                            height: 26

                            Image {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                source: trayItem.modelData.icon
                                sourceSize.width: 22
                                sourceSize.height: 22
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            QsMenuAnchor {
                                id: menuAnchor
                                menu: trayItem.modelData.menu

                                anchor {
                                    window: trayWindow
                                    item: trayItem
                                    edges: Edges.Bottom
                                    gravity: Edges.Bottom
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons:
                                    Qt.LeftButton |
                                    Qt.RightButton |
                                    Qt.MiddleButton

                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        if (trayItem.modelData.onlyMenu &&
                                            trayItem.modelData.hasMenu) {
                                            menuAnchor.open()
                                        } else {
                                            trayItem.modelData.activate()
                                        }
                                    } else if (mouse.button === Qt.RightButton) {
                                        if (trayItem.modelData.hasMenu)
                                            menuAnchor.open()
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        trayItem.modelData.secondaryActivate()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
