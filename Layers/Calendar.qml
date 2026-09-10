import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.Data as Dat
import qs.Widgets as Wid

Scope {
    id: root
    property bool shouldShow: false
    property var targetScreen: null
    property bool contentVisible: false

    Wid.P3rTransition3 { id: calTransition }

    LazyLoader {
        active: true
        PanelWindow {
            id: calWindow
            visible: root.shouldShow
            screen: root.targetScreen
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { left: true; right: true; top: true; bottom: true }

            Connections {
                target: calTransition
                function onPeaked() { contentVisible = true; }
            }

            onVisibleChanged: {
                if (visible) {
                    contentVisible = false;
                    calTransition.targetScreen = root.targetScreen;
                    calTransition.shouldShow = true;
                } else {
                    contentVisible = false;
                }
            }

            Rectangle { anchors.fill: parent; color: "#0b113d"; visible: root.contentVisible; z: 0 }

            Item {
                anchors.fill: parent
                visible: root.contentVisible
                z: 1
                clip: true
                Rectangle {
                    width: parent.width * 2
                    height: parent.height * 0.2
                    x: -parent.width * 0.2
                    y: parent.height * -0.1
                    color: "#1a4fa8"
                    transform: Rotation { origin.x: parent.width / 2; origin.y: parent.height / 2; angle: 20 }
                }
            }

            Item {
                anchors.fill: parent
                visible: root.contentVisible
                z: 2
                Rectangle {
                    width: parent.width * 200
                    height: 5
                    x: -parent.width * 0.2
                    y: parent.height * 0.99
                    color: "white"
                    transform: Rotation { origin.x: parent.width / 2; origin.y: parent.height / 2; angle: -20 }
                }
            }

            Column {
                visible: root.contentVisible
                z: 2
                x: 40
                y: parent.height * 0.1
                spacing: -20
                Text {
                    text: Dat.Time.now.getFullYear()
                    font.family: "Montserrat"
                    font.pixelSize: 60
                    font.bold: true
                    color: "white"
                }
                Text {
                    text: Qt.formatDate(Dat.Time.now, "MMMM")
                    font.family: "Microsoft Yahei"
                    font.pixelSize: 30
                    font.bold: true
                    color: "#b4c8ff"
                }
                Text {
                    text: Dat.Time.now.getMonth() + 1
                    x: 200
                    topPadding: -100
                    font.family: "Microsoft Yahei"
                    font.pixelSize: 250
                    font.bold: true
                    color: "white"
                }
            }

            Item {
                id: datesContainer
                anchors.fill: parent
                visible: root.contentVisible
                z: 2

                // Ten-day diagonal: three days behind, today, and six ahead.
                // All non-today entries intentionally use identical sizing so
                // the diagonal reads consistently instead of growing/shrinking.
                Repeater {
                    model: 10
                    delegate: CalendarEntry {
                        required property int index
                        readonly property int offset: index - 3
                        readonly property var entryDate: {
                            var d = new Date(Dat.Time.now);
                            d.setDate(d.getDate() + offset);
                            d.setHours(12, 0, 0, 0);
                            return d;
                        }
                        readonly property bool isToday: offset === 0
                        readonly property bool isPast: offset < 0
                        readonly property real t: index / 9.0

                        x: parent.width * 0.055 + t * (parent.width * 0.88)
                        y: parent.height * 0.76 - t * (parent.height * 0.61) - numSize * 0.5

                        dateObj: entryDate
                        todayFlag: isToday
                        pastFlag: isPast
                    }
                }
            }

            FocusScope {
                anchors.fill: parent
                focus: visible
                z: 3
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

    component CalendarEntry: Item {
        id: entryRoot
        required property var dateObj
        required property bool todayFlag
        required property bool pastFlag

        readonly property int offset: {
            var d = new Date(Dat.Time.now);
            d.setHours(12, 0, 0, 0);
            return Math.round((dateObj - d) / 86400000);
        }

        // Keep every ordinary day visually uniform. Today is the only larger
        // entry because its concentric Persona highlight is the focal point.
        readonly property real numSize: todayFlag ? 86 : 54
        readonly property real dayLabelSize: todayFlag ? 17 : 12
        readonly property real alphaVal: todayFlag ? 1.0 : (pastFlag ? 0.68 : 0.78)
        readonly property real moonR: todayFlag ? 33 : 15
        readonly property real moonPhaseDeg: Dat.Time.moonPhaseDegreeFor(dateObj)

        readonly property var dayNames: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        readonly property int dayOfWeek: dateObj.getDay()
        readonly property bool isSunday: dayOfWeek === 0
        readonly property bool isSaturday: dayOfWeek === 6

        width: numSize * 2.8
        height: numSize * 1.8
        opacity: alphaVal

        Item {
            visible: entryRoot.todayFlag
            anchors.left: parent.left - entryRoot.numSize * 0.7
            anchors.verticalCenter: parent.verticalCenter
            width: entryRoot.numSize * 1.5
            height: width
            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 7
                width: entryRoot.numSize * 2.3
                height: width
                radius: width / 2
                color: "transparent"
                border.color: "#6490ff"
                border.width: 15
                opacity: 0.6
            }
            Rectangle {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                width: entryRoot.numSize
                height: width
                radius: width / 2
                color: "transparent"
                border.color: "#6490ff"
                border.width: 10
                opacity: 0.6
            }
        }

        Text {
            id: dayNumText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: entryRoot.dateObj.getDate()
            font.family: "Microsoft Yahei"
            font.pixelSize: entryRoot.numSize
            font.bold: true
            color: "white"
        }

        Column {
            anchors.left: dayNumText.right
            anchors.leftMargin: 4
            anchors.bottom: dayNumText.bottom
            anchors.bottomMargin: Math.max(18, entryRoot.numSize * 0.48)
            spacing: 2
            Text {
                text: entryRoot.dayNames[entryRoot.dayOfWeek]
                font.family: "Bahnschrift Condensed"
                font.pixelSize: entryRoot.dayLabelSize
                font.bold: true
                color: entryRoot.isSunday ? "#ff4444" : entryRoot.isSaturday ? "#4488ff" : "white"
            }
            Rectangle {
                visible: entryRoot.isSunday || entryRoot.isSaturday
                width: parent.children[0].implicitWidth
                height: 1.5
                color: entryRoot.isSunday ? "#ff4444" : "#4488ff"
            }
        }

        Item {
            id: moonItem
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: entryRoot.numSize * 1.05
            anchors.left: parent.left
            anchors.leftMargin: entryRoot.numSize * 1.55
            width: entryRoot.moonR
            height: entryRoot.moonR * 2

            Rectangle {
                visible: entryRoot.todayFlag
                anchors.centerIn: parent
                width: entryRoot.moonR * 2 + 6
                height: width
                radius: width / 2
                color: "transparent"
                border.color: "#ffe700"
                border.width: 1.5
            }

            Item {
                id: moonSphere
                anchors.centerIn: parent
                width: entryRoot.moonR * 2
                height: width
                clip: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: ShaderEffectSource {
                        sourceItem: Rectangle {
                            width: moonSphere.width
                            height: moonSphere.height
                            radius: moonSphere.width / 2
                            color: "white"
                        }
                    }
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }
                Rectangle {
                    width: parent.width / 2
                    height: parent.height
                    x: 0
                    color: entryRoot.moonPhaseDeg < 180 ? "#ffe700" : "#302c24"
                }
                Rectangle {
                    width: parent.width / 2
                    height: parent.height
                    x: parent.width / 2
                    color: entryRoot.moonPhaseDeg < 180 ? "#302c24" : "#ffe700"
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: width / 2
                    transform: Scale {
                        origin.x: moonSphere.width / 2
                        origin.y: moonSphere.height / 2
                        xScale: Math.cos(entryRoot.moonPhaseDeg * Math.PI / 180)
                        yScale: 1
                    }
                    color: Math.cos(entryRoot.moonPhaseDeg * Math.PI / 180) >= 0 ? "#302c24" : "#ffe700"
                }
            }
        }

        Behavior on x { SpringAnimation { spring: 2.0; damping: 0.3 } }
        Behavior on y { SpringAnimation { spring: 2.0; damping: 0.3 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
