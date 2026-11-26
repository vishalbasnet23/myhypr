pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import "patro/Bikram.js" as Bikram
import "patro/Nepali.js" as Nepali

// Hover popout for the date segment of the bar clock: month calendar.
// Chevrons or scroll change month, clicking the title jumps back to today.
// Standalone from the dashboard calendar (that one is tied to ScreenState).
// Gregorian month on the left, Bikram Sambat month (NepaliCalendar.qml) on the right.
Column {
    id: root

    // First of the month being shown. Content.qml recreates this popout on
    // every open, so it always starts on the current month.
    property date viewDate: new Date(Time.date.getFullYear(), Time.date.getMonth(), 1)
    readonly property bool isCurrentMonth: viewDate.getMonth() === Time.date.getMonth() && viewDate.getFullYear() === Time.date.getFullYear()

    // 42 Dates (six weeks from the Sunday on/before the 1st), same shape as
    // NepaliCalendar's grid so both months size identically.
    readonly property var adCells: {
        const first = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1);
        const start = new Date(first.getFullYear(), first.getMonth(), 1 - first.getDay());
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
        return out;
    }

    function shiftMonth(delta: int): void {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + delta, 1);
    }

    readonly property int monthWidth: 260
    readonly property var todayBs: Bikram.today(Time.date)

    // Shared row metrics so the Bikram Sambat month lines up with the Gregorian
    // one. Sized from Latin text (the Gregorian month's natural size); the
    // Devanagari side is centred inside the same rows.
    readonly property real titleHeight: titleProbe.implicitHeight + Tokens.padding.extraSmall * 2
    readonly property real weekdayHeight: dayProbe.implicitHeight
    readonly property real dayHeight: weekdayHeight + Tokens.padding.small * 2
    readonly property int cellSpacing: 3

    spacing: Tokens.spacing.medium
    width: monthWidth * 2 + Tokens.spacing.large * 2 + 1

    // Measurement only; Column skips invisible children.
    Item {
        visible: false

        StyledText {
            id: titleProbe
            text: "November"
            font: Tokens.font.title.small
        }
        StyledText {
            id: dayProbe
            text: "28"
            font: Tokens.font.body.small
        }
    }

    RowLayout {
        width: parent.width
        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: "calendar_month"
            fontStyle: Tokens.font.icon.extraLarge
            color: Colours.palette.m3tertiary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Time.format("dddd, d MMMM")
                font: Tokens.font.title.medium
            }

            StyledText {
                text: root.todayBs ? Nepali.formatDate(root.todayBs, {
                    language: "Nepali",
                    numerals: "Devanagari",
                    showWeekday: true,
                    weekday: Time.date.getDay()
                }) : Tr.tr("Calendar")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    RowLayout {
        width: parent.width
        spacing: Tokens.spacing.large

        Column {
            id: adCol

            Layout.alignment: Qt.AlignTop
            width: root.monthWidth
            Layout.preferredWidth: root.monthWidth
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
                width: parent.width
                spacing: Tokens.spacing.extraSmall

                IconButton {
                    isRound: true
                    icon: "chevron_left"
                    type: IconButton.Text
                    font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                    padding: Tokens.padding.small
                    onClicked: root.shiftMonth(-1)
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    implicitHeight: root.titleHeight

                    StateLayer {
                        color: Colours.palette.m3primary
                        radius: height / 2
                        disabled: root.isCurrentMonth
                        onClicked: root.viewDate = new Date(Time.date.getFullYear(), Time.date.getMonth(), 1)
                    }

                    StyledText {
                        id: monthLabel

                        anchors.centerIn: parent
                        text: root.viewDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                        color: Colours.palette.m3primary
                        font: Tokens.font.title.builders.small.capitalisation(Font.Capitalize).build()
                    }
                }

                IconButton {
                    isRound: true
                    icon: "chevron_right"
                    type: IconButton.Text
                    font: Tokens.font.icon.builders.small.weight(Font.Bold).build()
                    padding: Tokens.padding.small
                    onClicked: root.shiftMonth(1)
                }
            }

            GridLayout {
                width: parent.width
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
                        text: Qt.locale().dayName(index, Locale.ShortFormat)
                        font: Tokens.font.body.builders.small.weight(Font.Medium).build()
                        color: (index === 0 || index === 6) ? Colours.palette.m3tertiary : Colours.palette.m3onSurface
                    }
                }

                Repeater {
                    model: root.adCells

                    Item {
                        id: dayItem

                        required property date modelData
                        required property int index
                        readonly property bool inMonth: modelData.getMonth() === root.viewDate.getMonth()
                        // Hide days after the month ends (the slot stays, so the
                        // height still matches the Nepali side).
                        readonly property bool afterMonth: !inMonth && index >= 7

                        opacity: afterMonth ? 0 : 1
                        readonly property bool weekend: modelData.getDay() === 0 || modelData.getDay() === 6
                        readonly property bool isToday: modelData.toDateString() === Time.date.toDateString()

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: root.dayHeight

                        StyledRect {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height)
                            height: width
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3primary
                            visible: dayItem.isToday
                        }

                        StyledText {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: dayItem.modelData.getDate()
                            font: Tokens.font.body.small
                            color: {
                                if (dayItem.isToday)
                                    return Colours.palette.m3onPrimary;
                                if (dayItem.weekend)
                                    return Colours.palette.m3tertiary;
                                return dayItem.inMonth ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant;
                            }
                            opacity: dayItem.isToday || dayItem.inMonth ? 1 : 0.4
                        }
                    }
                }
            }
        }

        StyledRect {
            Layout.fillHeight: true
            implicitWidth: 1
            color: Colours.mutedLine
        }

        NepaliCalendar {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: root.monthWidth
            titleHeight: root.titleHeight
            weekdayHeight: root.weekdayHeight
            dayHeight: root.dayHeight
            cellSpacing: root.cellSpacing
        }
    }
}
