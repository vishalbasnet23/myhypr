pragma ComponentBehavior: Bound

import "patro/Bikram.js" as Bikram
import "patro/Nepali.js" as Nepali
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Bikram Sambat month view, Devanagari.
// Conversion logic is vendored from yogeshojha/patro (see patro/README.md).
// Saturday is the weekly holiday in Nepal, drawn in the error colour.
ColumnLayout {
    id: root

    readonly property var todayBs: Bikram.today(Time.date)
    readonly property bool inRange: todayBs !== null

    // Row metrics, set by CalendarPopout to match the Gregorian month.
    property real titleHeight: 32
    property real weekdayHeight: 20
    property real dayHeight: 28
    property int cellSpacing: 3

    property int viewYear: inRange ? todayBs.year : Bikram.firstYear()
    property int viewMonth: inRange ? todayBs.month : 1

    readonly property bool viewingToday: inRange && viewYear === todayBs.year && viewMonth === todayBs.month
    readonly property bool canGoBack: viewYear > Bikram.firstYear() || viewMonth > 1
    readonly property bool canGoForward: viewYear < Bikram.lastYear() || viewMonth < 12

    // Flat list of cells (null = padding), weeks start Sunday. Padded to six
    // weeks like Qt's MonthGrid so the height never changes between months.
    readonly property var cells: {
        const flat = Bikram.monthGrid(viewYear, viewMonth, 0).reduce((acc, w) => acc.concat(w), []);
        while (flat.length < 42)
            flat.push(null);
        return flat;
    }

    readonly property var opts: ({
            language: "Nepali",
            numerals: "Devanagari"
        })

    function shiftMonth(delta: int): void {
        const next = Bikram.addMonths(viewYear, viewMonth, delta);
        viewYear = next.year;
        viewMonth = next.month;
    }

    function goToday(): void {
        if (!inRange)
            return;
        viewYear = todayBs.year;
        viewMonth = todayBs.month;
    }

    spacing: Tokens.spacing.medium

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y > 0)
                root.shiftMonth(-1);
            else if (event.angleDelta.y < 0)
                root.shiftMonth(1);
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall

        IconButton {
            isRound: true
            icon: "chevron_left"
            type: IconButton.Text
            font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
            padding: Tokens.padding.small
            disabled: !root.canGoBack
            onClicked: root.shiftMonth(-1)
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            implicitHeight: root.titleHeight

            StateLayer {
                color: Colours.palette.m3primary
                radius: height / 2
                disabled: root.viewingToday
                onClicked: root.goToday()
            }

            StyledText {
                anchors.centerIn: parent
                text: Nepali.monthTitle(root.viewYear, root.viewMonth, root.opts) + (Bikram.confidence(root.viewYear) === "provisional" ? " *" : "")
                color: Colours.palette.m3primary
                font: Tokens.font.title.small
            }
        }

        IconButton {
            isRound: true
            icon: "chevron_right"
            type: IconButton.Text
            font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
            padding: Tokens.padding.small
            disabled: !root.canGoForward
            onClicked: root.shiftMonth(1)
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: root.cellSpacing
        columnSpacing: root.cellSpacing

        Repeater {
            model: 7

            StyledText {
                required property int index

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: root.weekdayHeight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: Nepali.weekdayShort(index, "Nepali")
                font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                color: Nepali.isWeeklyHoliday(index) ? Colours.palette.m3error : Colours.palette.m3onSurface
            }
        }

        Repeater {
            model: root.cells

            Item {
                id: cell

                required property var modelData
                readonly property bool filled: modelData !== null
                readonly property bool isToday: filled && root.inRange && modelData.year === root.todayBs.year && modelData.month === root.todayBs.month && modelData.day === root.todayBs.day
                readonly property bool holiday: filled && Nepali.isWeeklyHoliday(modelData.weekday)

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: root.dayHeight

                StyledRect {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary
                    visible: cell.isToday
                }

                StyledText {
                    id: dayCol

                    anchors.centerIn: parent
                    visible: cell.filled
                    text: cell.filled ? Nepali.numerals(cell.modelData.day, "Devanagari") : ""
                    font: Tokens.font.body.small
                    color: cell.isToday ? Colours.palette.m3onPrimary : cell.holiday ? Colours.palette.m3error : Colours.palette.m3onSurface
                }
            }
        }
    }

    StyledText {
        visible: !root.inRange
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "Outside BS 2000–2090"
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }
}
