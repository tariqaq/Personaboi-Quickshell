import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "../Data" as Dat

Scope {
    id: workspaceScope

    readonly property int currentWorkspace: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property var shownWorkspaces: {
        const base = [1, 2, 3, 4, 5]
        if (currentWorkspace >= 6 && currentWorkspace <= 10)
            return base.concat(["...", currentWorkspace])
        return base
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: workspaceWindow
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
            }

            margins {
                top: 18
                left: 18
            }

            implicitWidth: workspaceRow.implicitWidth + 20
            implicitHeight: 42
            color: "transparent"
            visible: Hyprland.connected
            focusable: false

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "personaboi.workspaces"

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: "#d90c0f1d"
                border.width: 1
                border.color: "#6652A4CD"

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 4
                    radius: 2
                    color: Dat.Colors.color5
                }

                Row {
                    id: workspaceRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: workspaceScope.shownWorkspaces

                        delegate: Item {
                            id: workspaceItem
                            required property var modelData

                            readonly property bool isNumber: typeof modelData === "number"
                            readonly property bool isActive: isNumber && modelData === workspaceScope.currentWorkspace

                            width: modelData === "..." ? 24 : (modelData === 10 ? 34 : 30)
                            height: 28

                            Rectangle {
                                id: workspaceChip
                                anchors.fill: parent
                                radius: 7
                                color: workspaceItem.isActive
                                    ? Dat.Colors.color3
                                    : (workspaceMouse.containsMouse && workspaceItem.isNumber
                                        ? "#4452A4CD"
                                        : "transparent")
                                border.width: workspaceItem.isActive ? 1 : 0
                                border.color: Dat.Colors.color6

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: workspaceItem.modelData
                                    color: workspaceItem.isActive ? Dat.Colors.color0 : Dat.Colors.foreground
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: workspaceItem.modelData === "..." ? 13 : 14
                                    font.bold: workspaceItem.isActive
                                }
                            }

                            MouseArea {
                                id: workspaceMouse
                                anchors.fill: parent
                                enabled: workspaceItem.isNumber
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: Hyprland.dispatch("workspace " + workspaceItem.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
