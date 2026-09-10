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

            // A thin full-width shell strip reserves the top edge so tiled
            // windows always begin below the workspace indicator.
            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 30
            exclusiveZone: 30
            color: "transparent"
            visible: Hyprland.connected
            focusable: false

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Normal
            WlrLayershell.namespace: "personaboi.workspaces"

            Rectangle {
                id: workspacePill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 4
                anchors.topMargin: 3

                width: workspaceRow.implicitWidth + 12
                height: 24
                radius: 7
                color: "#d90c0f1d"
                border.width: 1
                border.color: "#6652A4CD"

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 3
                    radius: 2
                    color: Dat.Colors.color5
                }

                Row {
                    id: workspaceRow
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 1
                    spacing: 2

                    Repeater {
                        model: workspaceScope.shownWorkspaces

                        delegate: Item {
                            id: workspaceItem
                            required property var modelData

                            readonly property bool isNumber: typeof modelData === "number"
                            readonly property bool isActive: isNumber && modelData === workspaceScope.currentWorkspace

                            width: modelData === "..." ? 18 : (modelData === 10 ? 27 : 23)
                            height: 20

                            Rectangle {
                                id: workspaceChip
                                anchors.fill: parent
                                radius: 5
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
                                    font.pixelSize: workspaceItem.modelData === "..." ? 10 : 11
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
