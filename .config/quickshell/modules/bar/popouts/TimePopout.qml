import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/modules/common"
import ".."

/**
 * Replaces waybar's group/time drawer AND clock#4's tooltip.
 *
 * waybar rendered a calendar through pango in a tooltip:
 *   "<big>{:%B %Y}</big>\n<tt><small>{calendar}</small></tt>"
 * and revealed the Kathmandu clock by expanding the group. Both land here
 * instead, which is what the popout buys: the calendar is a real grid rather
 * than monospace-padded text.
 */
ColumnLayout {
    id: root

    // Layouts clobber implicitWidth, so the panel reads this instead.
    property int preferredWidth: 300

    readonly property var now: clock.date
    property int monthOffset: 0

    readonly property date shown: new Date(now.getFullYear(), now.getMonth() + monthOffset, 1)
    readonly property int daysInMonth: new Date(shown.getFullYear(), shown.getMonth() + 1, 0).getDate()
    readonly property int firstWeekday: shown.getDay()
    readonly property bool isThisMonth: monthOffset === 0

    spacing: 8

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // Kathmandu is UTC+05:45 with no DST, so a fixed offset is exact.
    function kathmandu() {
        const utcMs = root.now.getTime() + root.now.getTimezoneOffset() * 60000;
        return new Date(utcMs + 5.75 * 3600000);
    }

    function hhmm(d) {
        let h = d.getHours();
        const ap = h < 12 ? "AM" : "PM";
        h = h % 12;
        if (h === 0)
            h = 12;
        const m = d.getMinutes();
        return `${h < 10 ? "0" + h : h}:${m < 10 ? "0" + m : m} ${ap}`;
    }

    PopoutHeader {
        text: "Calendar"
    }

    // ---- header: month + paging ----
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        BarText {
            text: `${["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][root.shown.getMonth()]} ${root.shown.getFullYear()}`
            color: Glass.subtext1
            pixelSize: Glass.fontTitle
        }

        Item {
            Layout.fillWidth: true
        }

        Pager {
            glyph: "‹"
            onActivated: root.monthOffset--
        }

        Pager {
            glyph: "•"
            enabled: !root.isThisMonth
            onActivated: root.monthOffset = 0
        }

        Pager {
            glyph: "›"
            onActivated: root.monthOffset++
        }
    }

    // ---- weekday header ----
    GridLayout {
        columns: 7
        columnSpacing: 2
        rowSpacing: 2
        Layout.alignment: Qt.AlignHCenter

        Repeater {
            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

            delegate: BarText {
                required property string modelData

                text: modelData
                color: Glass.textFaint
                pixelSize: Glass.fontMeta
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 26
            }
        }

        // leading blanks so the 1st lands on the right weekday
        Repeater {
            model: root.firstWeekday

            delegate: Item {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 22
            }
        }

        Repeater {
            model: root.daysInMonth

            delegate: Rectangle {
                required property int index

                readonly property int day: index + 1
                readonly property bool today: root.isThisMonth && day === root.now.getDate()

                Layout.preferredWidth: 26
                Layout.preferredHeight: 22
                radius: Glass.itemRadius
                // Glass.css uses @sel (white) for "the selected thing"
                color: today ? Qt.rgba(1, 1, 1, 0.20) : "transparent"

                BarText {
                    anchors.centerIn: parent
                    text: parent.day
                    color: parent.today ? Glass.sel : Glass.textGlass
                    pixelSize: Glass.fontMeta
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 2
        implicitHeight: 1
        color: Glass.glassBorder
    }

    // ---- the second clock that used to live in the drawer ----
    PopoutRow {
        label: "Kathmandu"
        icon: "󰥔"
        value: root.hhmm(root.kathmandu())
    }

    PopoutRow {
        label: "Local"
        icon: "󰀠"
        value: root.hhmm(root.now)
    }

    component Pager: Rectangle {
        id: pager

        property string glyph: ""
        signal activated

        implicitWidth: 20
        implicitHeight: 20
        radius: Glass.itemRadius
        color: ma.containsMouse && pager.enabled ? Glass.uiHover : "transparent"
        opacity: pager.enabled ? 1 : 0.35

        BarText {
            anchors.centerIn: parent
            text: pager.glyph
            color: Glass.textGlass
        }

        MouseArea {
            id: ma

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: pager.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (pager.enabled)
                pager.activated()
        }
    }
}
