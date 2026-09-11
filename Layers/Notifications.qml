import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../Data" as Dat

Scope {
    id: root

    property var history: []
    property bool historyOpen: false
    property int historySeq: 0

    function historyTime(ms) {
        var d = new Date(ms)
        var hh = ("0" + d.getHours()).slice(-2)
        var mm = ("0" + d.getMinutes()).slice(-2)
        return hh + ":" + mm
    }

    function remember(notification) {
        var item = {
            seq: ++root.historySeq,
            timestamp: Date.now(),
            appName: notification.appName || "Notification",
            appIcon: notification.appIcon || "",
            image: notification.image || "",
            summary: notification.summary || "Notification",
            body: notification.body || "",
            urgency: notification.urgency
        }

        var next = [item].concat(root.history)
        if (next.length > 50)
            next = next.slice(0, 50)
        root.history = next
    }

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
            root.remember(notification)
            notification.tracked = true
        }
    }

    // Compact bell aligned with the 24 px workspace strip.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: historyButtonWindow
            required property ShellScreen modelData
            screen: modelData
            anchors.top: true
            anchors.right: true
            margins.top: 1
            margins.right: 2
            implicitWidth: 30
            implicitHeight: 21
            color: "transparent"
            focusable: false

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "personaboi.notification-button"

            mask: Region { item: historyButton }

            Rectangle {
                id: historyButton
                anchors.fill: parent
                radius: 6
                color: historyMouse.containsMouse || root.historyOpen ? "#d952A4CD" : "#d90c0f1d"
                border.width: 1
                border.color: root.historyOpen ? Dat.Colors.color5 : "#6652A4CD"

                Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: root.historyOpen ? Dat.Colors.color0 : Dat.Colors.foreground
                }

                Rectangle {
                    visible: root.history.length > 0
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 2
                    anchors.topMargin: 2
                    width: 5
                    height: 5
                    radius: 3
                    color: Dat.Colors.color5
                }

                MouseArea {
                    id: historyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.historyOpen = !root.historyOpen
                }
            }
        }
    }

    // Scrollable session notification history.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: historyWindow
            required property ShellScreen modelData
            screen: modelData
            anchors.top: true
            anchors.right: true
            margins.top: 30
            margins.right: 8
            implicitWidth: 390
            implicitHeight: 470
            visible: root.historyOpen
            color: "transparent"
            focusable: false

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "personaboi.notification-history"

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: "#f20c0f1d"
                border.width: 1
                border.color: "#8852A4CD"
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    anchors.leftMargin: 7
                    width: 4
                    radius: 2
                    color: Dat.Colors.color5
                }

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: 22
                    anchors.topMargin: 14
                    text: "NOTIFICATIONS"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    color: Dat.Colors.color15
                }

                Text {
                    anchors.right: clearButton.left
                    anchors.top: parent.top
                    anchors.rightMargin: 10
                    anchors.topMargin: 16
                    text: root.history.length + " / 50"
                    font.family: "Noto Sans"
                    font.pixelSize: 10
                    color: Dat.Colors.color8
                }

                Rectangle {
                    id: clearButton
                    anchors.right: closeHistory.left
                    anchors.top: parent.top
                    anchors.rightMargin: 7
                    anchors.topMargin: 10
                    width: 56
                    height: 26
                    radius: 7
                    color: clearMouse.containsMouse ? "#4452A4CD" : "#221788B6"
                    border.width: 1
                    border.color: "#6652A4CD"

                    Text {
                        anchors.centerIn: parent
                        text: "CLEAR"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        color: Dat.Colors.color15
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.history = []
                    }
                }

                Rectangle {
                    id: closeHistory
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 10
                    anchors.topMargin: 10
                    width: 26
                    height: 26
                    radius: 13
                    color: closeHistoryMouse.containsMouse ? "#4452A4CD" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.pixelSize: 18
                        color: Dat.Colors.color15
                    }

                    MouseArea {
                        id: closeHistoryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.historyOpen = false
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 20
                    anchors.rightMargin: 14
                    anchors.topMargin: 46
                    height: 1
                    color: "#4452A4CD"
                }

                Flickable {
                    id: historyFlick
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 18
                    anchors.rightMargin: 10
                    anchors.topMargin: 56
                    anchors.bottomMargin: 12
                    contentWidth: width
                    contentHeight: historyColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: historyColumn
                        width: historyFlick.width
                        spacing: 8

                        Text {
                            visible: root.history.length === 0
                            width: parent.width
                            topPadding: 48
                            horizontalAlignment: Text.AlignHCenter
                            text: "NO NOTIFICATIONS YET"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Dat.Colors.color8
                        }

                        Repeater {
                            model: ScriptModel {
                                values: root.history
                                objectProp: "seq"
                            }

                            delegate: Rectangle {
                                id: historyCard
                                required property var modelData
                                width: historyColumn.width
                                height: Math.max(72, historyContent.implicitHeight + 22)
                                radius: 10
                                color: "#b6172236"
                                border.width: 1
                                border.color: modelData.urgency === NotificationUrgency.Critical ? Dat.Colors.color1 : "#4452A4CD"

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 5
                                    anchors.topMargin: 8
                                    anchors.bottomMargin: 8
                                    width: 3
                                    radius: 2
                                    color: modelData.urgency === NotificationUrgency.Critical ? Dat.Colors.color1 : Dat.Colors.color5
                                }

                                Row {
                                    id: historyContent
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 11
                                    anchors.leftMargin: 15
                                    spacing: 10

                                    Rectangle {
                                        width: 38
                                        height: 38
                                        radius: 9
                                        color: "#33209FCD"
                                        border.width: 1
                                        border.color: "#555FCFDF"

                                        Image {
                                            anchors.centerIn: parent
                                            width: 26
                                            height: 26
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            source: {
                                                if (historyCard.modelData.image !== "")
                                                    return historyCard.modelData.image
                                                if (historyCard.modelData.appIcon !== "")
                                                    return Quickshell.iconPath(historyCard.modelData.appIcon, true)
                                                return Quickshell.iconPath("dialog-information", true)
                                            }
                                        }
                                    }

                                    Column {
                                        width: historyContent.width - 48
                                        spacing: 3

                                        Row {
                                            width: parent.width
                                            Text {
                                                width: parent.width - timeText.width - 8
                                                text: historyCard.modelData.appName
                                                elide: Text.ElideRight
                                                font.family: "Noto Sans"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: Dat.Colors.color5
                                            }
                                            Text {
                                                id: timeText
                                                text: root.historyTime(historyCard.modelData.timestamp)
                                                font.family: "Noto Sans"
                                                font.pixelSize: 9
                                                color: Dat.Colors.color8
                                            }
                                        }

                                        Text {
                                            width: parent.width
                                            text: historyCard.modelData.summary
                                            elide: Text.ElideRight
                                            font.family: "Noto Sans"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Dat.Colors.color15
                                        }

                                        Text {
                                            visible: text.length > 0
                                            width: parent.width
                                            text: historyCard.modelData.body
                                            textFormat: Text.PlainText
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 2
                                            elide: Text.ElideRight
                                            font.family: "Noto Sans"
                                            font.pixelSize: 10
                                            color: "#d9c2c3c6"
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

    // Live transient toasts. Keep them below the top-row notification button.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: notificationWindow
            required property ShellScreen modelData
            screen: modelData

            anchors.top: true
            anchors.right: true
            margins.top: 30
            margins.right: 8
            color: "transparent"
            implicitWidth: 390
            implicitHeight: Math.max(1, toastStack.implicitHeight)
            visible: !root.historyOpen && server.trackedNotifications.values.length > 0
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
                            if (modelData.urgency === NotificationUrgency.Critical)
                                return 8000
                            return 5000
                        }

                        Component.onCompleted: entered = true

                        HoverHandler { id: toastHover }

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
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.topMargin: 10
                                anchors.bottomMargin: 10
                                anchors.leftMargin: 7
                                color: toast.modelData.urgency === NotificationUrgency.Critical ? Dat.Colors.color1 : Dat.Colors.color5
                            }

                            Row {
                                id: content
                                anchors.left: parent.left
                                anchors.right: closeButton.left
                                anchors.top: parent.top
                                anchors.margins: 14
                                anchors.leftMargin: 20
                                anchors.rightMargin: 10
                                spacing: 12

                                Rectangle {
                                    width: 46
                                    height: 46
                                    radius: 11
                                    color: "#33209FCD"
                                    border.width: 1
                                    border.color: "#555FCFDF"

                                    Image {
                                        id: appIcon
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
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 10
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
