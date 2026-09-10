import QtQuick
import QtMultimedia
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.Widgets as Wid
import qs.Widgets.Info as Info

Scope {
    id: root
    property bool shouldShow: false
    property var targetScreen: null
    property bool contentVisible: false

    function compact(text, maxLen) {
        var s = text === undefined || text === null || text === "" ? "N/A" : String(text);
        return s.length > maxLen ? s.slice(0, maxLen - 1) + "…" : s;
    }

    Connections {
        target: root
        function onShouldShowChanged() {
            Info.SysInfo.active = root.shouldShow;
            if (root.shouldShow)
                Info.NetInfo.scanNetworks();
        }
    }

    Wid.P3rTransition { id: resumeTransition }

    LazyLoader {
        active: true
        PanelWindow {
            id: resumeWindow
            visible: root.shouldShow
            screen: root.targetScreen
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { left: true; right: true; top: true; bottom: true }

            onVisibleChanged: {
                if (visible) {
                    contentVisible = false;
                    resumeTransition.targetScreen = root.targetScreen;
                    resumeTransition.shouldShow = true;
                    contentDelayTimer.start();
                } else {
                    resumeVideo.stop();
                    contentVisible = false;
                }
            }

            Video {
                id: resumeVideo
                anchors.fill: parent
                source: Qt.resolvedUrl("../Assets/videos/Resume.mp4")
                fillMode: VideoOutput.PreserveAspectCrop
                loops: MediaPlayer.Infinite
                volume: 0
                z: 0
            }

            Timer {
                id: contentDelayTimer
                interval: 730
                repeat: false
                onTriggered: {
                    resumeVideo.play();
                    contentVisible = true;
                }
            }

            Item {
                id: contentRoot
                anchors.fill: parent
                z: 3
                visible: root.contentVisible
                property int activeCard: 0

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: parent.width * 0.028
                    anchors.top: parent.top
                    anchors.topMargin: parent.height * 0.09
                    spacing: 10

                    Text {
                        text: "LIST"
                        font.family: "proggyfonts"
                        font.pixelSize: 72
                        color: "#f6fbff"
                        leftPadding: 12
                    }

                    Repeater {
                        model: [
                            { badge: "I", title: "Stats", subtitle: "System telemetry and health", rank: 3 },
                            { badge: "II", title: "Network", subtitle: "Wi-Fi networks and connections", rank: 4 },
                            { badge: "III", title: "Bluetooth", subtitle: "Bluetooth devices", rank: 5 }
                        ]

                        delegate: Item {
                            id: cardWrap
                            required property var modelData
                            required property int index
                            width: 680
                            height: isActive ? 136 : 112
                            x: isActive ? 6 : 0
                            property bool isActive: contentRoot.activeCard === index

                            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                            Rectangle {
                                anchors.fill: parent
                                color: cardWrap.isActive ? "#8df6ff" : "#10185f"
                                border.color: cardWrap.isActive ? "#eaffff" : "#213ca0"
                                border.width: 2
                                rotation: -1
                            }

                            Rectangle {
                                x: -8
                                y: 10
                                width: 52
                                height: 66
                                color: cardWrap.isActive ? "#000" : "#0b113d"
                                border.color: cardWrap.isActive ? "#000" : "#9cf7ff"
                                border.width: 3
                                rotation: -8
                                Text {
                                    anchors.centerIn: parent
                                    text: cardWrap.modelData.badge
                                    font.family: "Montserrat"
                                    font.pixelSize: 28
                                    color: cardWrap.isActive ? "#fff" : "#d2fdff"
                                    rotation: 8
                                }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 62
                                anchors.top: parent.top
                                anchors.topMargin: 14
                                text: cardWrap.modelData.title
                                font.family: "Montserrat"
                                font.pixelSize: 48
                                color: cardWrap.isActive ? "#000" : "#a5f6ff"
                            }

                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 20
                                anchors.top: parent.top
                                anchors.topMargin: 10
                                spacing: 8
                                Text { text: "RANK"; font.family: "Montserrat"; font.pixelSize: 22; color: cardWrap.isActive ? "#000" : "#9ffbff"; anchors.bottom: parent.bottom; bottomPadding: 8 }
                                Text { text: cardWrap.modelData.rank; font.family: "Montserrat"; font.pixelSize: 60; color: cardWrap.isActive ? "#000" : "#9ffbff" }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 64
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 12
                                height: 32
                                color: cardWrap.isActive ? "#000" : "#85f4ff"
                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    text: cardWrap.modelData.subtitle
                                    font.family: "Montserrat"
                                    font.pixelSize: 20
                                    color: cardWrap.isActive ? "#fff" : "#041238"
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            HoverHandler { onHoveredChanged: { if (hovered) contentRoot.activeCard = cardWrap.index; } }
                            TapHandler { onTapped: contentRoot.activeCard = cardWrap.index }
                        }
                    }
                }

                Rectangle {
                    id: detailPanel
                    anchors.right: parent.right
                    anchors.rightMargin: parent.width * 0.045
                    anchors.top: parent.top
                    anchors.topMargin: parent.height * 0.075
                    width: Math.min(parent.width * 0.41, 660)
                    height: parent.height * 0.82
                    color: "#f30a1248"
                    border.color: "#3260d0"
                    border.width: 2

                    Rectangle {
                        id: detailHeader
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 92
                        color: "#aaf8ff"

                        property string indexText: ["01", "02", "03"][contentRoot.activeCard]
                        property string titleText: ["System Stats", "Wifi networks", "Bluetooth devices"][contentRoot.activeCard]

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 18
                            spacing: 14
                            Text { text: detailHeader.indexText; font.family: "Montserrat"; font.pixelSize: 40; color: "#08153f"; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: detailHeader.titleText; font.family: "Montserrat"; font.pixelSize: 34; color: "#08153f"; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    ScrollView {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: detailHeader.bottom
                        anchors.bottom: parent.bottom
                        anchors.topMargin: 14
                        anchors.bottomMargin: 8
                        clip: true

                        Column {
                            id: innerCol
                            width: detailPanel.width - 12
                            spacing: 8

                            Repeater {
                                model: {
                                    var ac = contentRoot.activeCard;
                                    var _refresh = Info.SysInfo.cpuUsage + Info.SysInfo.memUsage + Info.SysInfo.diskUsage + Info.SysInfo.uptime + Info.SysInfo.gpuUtil + Info.SysInfo.processCount;
                                    if (ac === 0) {
                                        return [
                                            { title: "OS", status: root.compact(Info.SysInfo.osName, 30) },
                                            { title: "HOST", status: root.compact(Info.SysInfo.hostname, 24) },
                                            { title: "KERNEL", status: root.compact(Info.SysInfo.kernel, 24) },
                                            { title: "UPTIME", status: Info.SysInfo.uptime },
                                            { title: "CPU", status: Math.round(Info.SysInfo.cpuUsage * 100) + "%" },
                                            { title: "CPU MODEL", status: root.compact(Info.SysInfo.cpuModel, 24) },
                                            { title: "LOGICAL CPUs", status: Info.SysInfo.cpuCores },
                                            { title: "LOAD 1/5/15", status: Info.SysInfo.loadAverage },
                                            { title: "RAM", status: Info.SysInfo.memText },
                                            { title: "ROOT DISK", status: Info.SysInfo.diskText },
                                            { title: "PROCESSES", status: Info.SysInfo.processCount },
                                            { title: "GPU", status: root.compact(Info.SysInfo.gpuName, 28) },
                                            { title: "GPU LOAD", status: Info.SysInfo.gpuUtil },
                                            { title: "GPU VRAM", status: Info.SysInfo.gpuMemory },
                                            { title: "GPU TEMP", status: Info.SysInfo.gpuTemp },
                                            { title: "SESSIONS", status: Info.SysInfo.loggedInUsers }
                                        ];
                                    }
                                    if (ac === 1) {
                                        return Info.NetInfo.networks.length === 0 ? [{ title: "Wi-Fi", status: "No networks found" }] : Info.NetInfo.networks.map(n => ({
                                            title: root.compact(n.ssid, 28),
                                            status: n.active ? "Connected" : (n.strength + "%")
                                        }));
                                    }
                                    return Info.BluetoothInfo.friendlyDeviceList.length === 0 ? [
                                        { title: Info.BluetoothInfo.available ? "Bluetooth" : "Adapter", status: Info.BluetoothInfo.enabled ? "No Devices" : "Disabled" }
                                    ] : Info.BluetoothInfo.friendlyDeviceList.map(d => ({
                                        title: root.compact(d.name, 28),
                                        status: d.connected ? "Connected" : (d.paired ? "Paired" : "Found")
                                    }));
                                }

                                delegate: Item {
                                    required property var modelData
                                    width: innerCol.width
                                    height: 50

                                    Rectangle { anchors.fill: parent; color: "#f0081248"; border.color: "#20357f"; border.width: 1 }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.title
                                        font.family: "Montserrat"
                                        font.pixelSize: 18
                                        color: "#f2fcff"
                                        width: parent.width * 0.42
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.min(parent.width * 0.53, statusText.implicitWidth + 26)
                                        height: 32
                                        color: "#8df6ff"
                                        Text {
                                            id: statusText
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            text: modelData.status
                                            font.family: "Montserrat"
                                            font.pixelSize: 14
                                            color: "#06133b"
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea { anchors.fill: parent; z: -1; onClicked: root.shouldShow = false }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.shouldShow = false;
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
