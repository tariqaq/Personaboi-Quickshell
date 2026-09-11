import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../Data" as Dat

Scope {
    id: root

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: false
        persistenceSupported: false
        inlineReplySupported: false

        onNotification: notification => {
            notification.tracked = true
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: notificationWindow
            required property ShellScreen modelData
            screen: modelData

            anchors.top: true
            anchors.right: true
            margins.top: 12
            margins.right: 12
            color: "transparent"
            implicitWidth: 390
            implicitHeight: Math.max(1, toastStack.implicitHeight)
            visible: server.trackedNotifications.values.length > 0
            focusable: false

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "personaboi-notifications"

            Column {
                id: toastStack
                width: parent.width
                spacing: 10

                Repeater {
                    model: ScriptModel {
                        values: server.trackedNotifications.values
                    }

                    delegate: Item {
                        id: toast
                        required property var modelData
                        width: toastStack.width
                        height: card.height
                        property bool entered: false
                        property int lifetimeMs: {
                            if (modelData.expireTimeout > 0)
                                return Math.max(2500, Math.round(modelData.expireTimeout * 1000))
                            return modelData.urgency === NotificationUrgency.Critical ? 8000 : 5000
                        }

                        Component.onCompleted: entered = true

                        HoverHandler {
                            id: toastHover
                        }

                        Timer {
                            interval: toast.lifetimeMs
                            repeat: false
                            running: !toastHover.hovered
                            onTriggered: if (toast.modelData) toast.modelData.expire()
                        }

                        Rectangle {
                            id: card
                            width: parent.width
                            height: Math.max(92, content.implicitHeight + 28)
                            radius: 14
                            color: "#ec0c0f1d"
                            border.width: 1
                            border.color: toast.modelData.urgency === NotificationUrgency.Critical ? Dat.Colors.color1 : "#8852A4CD"
                            x: toast.entered ? 0 : 42
                            opacity: toast.entered ? 1.0 : 0.0

                            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            Rectangle {
                                width: 4
                                radius: 2
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                    leftMargin: 7
                                    topMargin: 10
                                    bottomMargin: 10
                                }
                                color: toast.modelData.urgency === NotificationUrgency.Critical ? Dat.Colors.color1 : Dat.Colors.color5
                            }

                            Row {
                                id: content
                                anchors {
                                    left: parent.left
                                    right: closeButton.left
                                    top: parent.top
                                    margins: 14
                                    leftMargin: 20
                                    rightMargin: 10
                                }
                                spacing: 12

                                Rectangle {
                                    width: 46
                                    height: 46
                                    radius: 11
                                    color: "#33209FCD"
                                    border.width: 1
                                    border.color: "#555FCFDF"

                                    Image {
                                        anchors.centerIn: parent
                                        width: 30
                                        height: 30
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        source: {
                                            if (toast.modelData.image && toast.modelData.image !== "")
                                                return toast.modelData.image
                                            if (toast.modelData.appIcon && toast.modelData.appIcon !== "")
                                                return Quickshell.iconPath(toast.modelData.appIcon, true)
                                            return Quickshell.iconPath("dialog-information", true)
                                        }
                                    }
                                }

                                Column {
                                    width: content.width - 58
                                    spacing: 4

                                    Row {
                                        width: parent.width
                                        spacing: 8

                                        Text {
                                            text: toast.modelData.appName || "Notification"
                                            color: Dat.Colors.color5
                                            font.family: "Noto Sans"
                                            font.pixelSize: 11
                                            font.bold: true
                                            elide: Text.ElideRight
                                            width: Math.min(implicitWidth, parent.width * 0.42)
                                        }

                                        Rectangle {
                                            width: 4
                                            height: 4
                                            radius: 2
                                            color: Dat.Colors.color8
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: toast.modelData.urgency === NotificationUrgency.Critical ? "CRITICAL" : "NOW"
                                            color: toast.modelData.urgency === NotificationUrgency.Critical ? Dat.Colors.color1 : Dat.Colors.color8
                                            font.family: "Noto Sans"
                                            font.pixelSize: 9
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        text: toast.modelData.summary || "Notification"
                                        color: Dat.Colors.color15
                                        font.family: "Noto Sans"
                                        font.pixelSize: 14
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        visible: text.length > 0
                                        text: toast.modelData.body || ""
                                        textFormat: Text.PlainText
                                        color: "#d9c2c3c6"
                                        font.family: "Noto Sans"
                                        font.pixelSize: 12
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                    }

                                    Row {
                                        visible: toast.modelData.actions && toast.modelData.actions.length > 0
                                        spacing: 7

                                        Repeater {
                                            model: toast.modelData.actions ? Math.min(toast.modelData.actions.length, 2) : 0

                                            delegate: Rectangle {
                                                required property int index
                                                property var action: toast.modelData.actions[index]
                                                width: Math.min(122, actionText.implicitWidth + 22)
                                                height: 27
                                                radius: 7
                                                color: actionMouse.containsMouse ? "#4452A4CD" : "#221788B6"
                                                border.width: 1
                                                border.color: "#6652A4CD"

                                                Text {
                                                    id: actionText
                                                    anchors.centerIn: parent
                                                    text: parent.action ? (parent.action.text || "Open") : "Open"
                                                    color: Dat.Colors.color15
                                                    font.family: "Noto Sans"
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                }

                                                MouseArea {
                                                    id: actionMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: if (parent.action) parent.action.invoke()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: closeButton
                                width: 25
                                height: 25
                                radius: 12.5
                                anchors {
                                    right: parent.right
                                    top: parent.top
                                    margins: 10
                                }
                                color: closeMouse.containsMouse ? "#4452A4CD" : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: Dat.Colors.color15
                                    font.pixelSize: 18
                                }

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (toast.modelData) toast.modelData.dismiss()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
