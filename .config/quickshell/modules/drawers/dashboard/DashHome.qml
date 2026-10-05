import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "root:/modules/common"
import "root:/modules/bar"
import "root:/modules/drawers"

/**
 * Profile + clock side by side, calendar card beneath - the reference's
 * layout, rebuilt in glass.
 *
 * The calendar is drawn here rather than reusing the bar's TimePopout: that
 * one carries its own heading and the Kathmandu/local rows, which belong to a
 * popout and not to this panel.
 */
Item {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property string uptime: ""
    // IconImage warns every frame for a missing file, so probe once.
    property bool hasFace: false

    readonly property var now: clock.date
    readonly property date firstOfMonth: new Date(now.getFullYear(), now.getMonth(), 1)
    readonly property int daysInMonth: new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
    readonly property int firstWeekday: firstOfMonth.getDay()
    readonly property int prevMonthDays: new Date(now.getFullYear(), now.getMonth(), 0).getDate()

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Process {
        running: true
        command: ["test", "-f", `${Quickshell.env("HOME")}/.face`]
        onExited: code => root.hasFace = code === 0
    }

    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        blockLoading: true
    }

    function readUptime() {
        uptimeFile.reload();
        const secs = parseFloat(uptimeFile.text().split(" ")[0]);
        if (isNaN(secs))
            return;
        const d = Math.floor(secs / 86400);
        const h = Math.floor((secs % 86400) / 3600);
        const m = Math.floor((secs % 3600) / 60);
        root.uptime = d > 0 ? `Up ${d} d ${h} h` : h > 0 ? `Up ${h} h ${m} min` : `Up ${m} min`;
    }

    Component.onCompleted: readUptime()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.readUptime()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Glass.cardGap

        // ---- profile + clock ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Glass.cardGap

            Card {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 118

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Glass.spaceS

                    Rectangle {
                        implicitWidth: 44
                        implicitHeight: 44
                        radius: width / 2
                        color: Glass.glassRaised

                        IconImage {
                            id: face

                            anchors.fill: parent
                            source: root.hasFace ? `${root.home}/.face` : ""
                            visible: root.hasFace && status === Image.Ready
                        }

                        BarText {
                            anchors.centerIn: parent
                            visible: !face.visible
                            text: (Quickshell.env("USER") ?? "?").charAt(0).toUpperCase()
                            pixelSize: Glass.fontHeading
                            color: Glass.subtext1
                        }
                    }

                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true

                        BarText {
                            text: Quickshell.env("USER") ?? ""
                            color: Glass.textGlass
                            pixelSize: Glass.fontTitle
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        BarText {
                            text: root.uptime
                            color: Glass.textDim
                            pixelSize: Glass.fontMeta
                        }
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 118

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    BarText {
                        text: Qt.formatDateTime(root.now, "HH:mm")
                        color: Glass.accent
                        pixelSize: Glass.fontClock
                    }

                    BarText {
                        text: Qt.formatDateTime(root.now, "dddd, MMMM d")
                        color: Glass.textDim
                        pixelSize: Glass.fontMeta
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // ---- calendar ----
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                columns: 7
                columnSpacing: 2
                rowSpacing: 2

                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]

                    delegate: BarText {
                        required property string modelData

                        text: modelData
                        color: Glass.textDim
                        pixelSize: Glass.fontMeta
                        horizontalAlignment: Text.AlignHCenter
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 26
                    }
                }

                // 6 weeks x 7 days, with the surrounding months dimmed rather
                // than blank - matches the reference.
                Repeater {
                    // Only the weeks this month actually spans - 42 cells always
                    // left a dead row at the bottom.
                    model: Math.ceil((root.firstWeekday + root.daysInMonth) / 7) * 7

                    delegate: Item {
                        required property int index

                        readonly property int dayNum: index - root.firstWeekday + 1
                        readonly property bool inMonth: dayNum >= 1 && dayNum <= root.daysInMonth
                        readonly property int shown: inMonth ? dayNum : dayNum < 1 ? root.prevMonthDays + dayNum : dayNum - root.daysInMonth
                        readonly property bool today: inMonth && dayNum === root.now.getDate()

                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 28

                        Rectangle {
                            anchors.centerIn: parent
                            width: 30
                            height: 24
                            radius: height / 2
                            color: parent.today ? Glass.accent : "transparent"
                        }

                        BarText {
                            anchors.centerIn: parent
                            text: parent.shown
                            pixelSize: Glass.fontMeta
                            color: parent.today ? Glass.crust : parent.inMonth ? Glass.textGlass : Glass.textDisabled
                        }
                    }
                }
            }
        }
    }
}
