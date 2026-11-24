pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

Item {
    id: root

    // Nepal is UTC+5:45 and does not observe DST, so computing it off the
    // system clock's live UTC offset (rather than hardcoding the local
    // offset) stays correct across the user's own DST changes.
    readonly property date kathmanduDate: new Date(Time.date.getTime() + Time.date.getTimezoneOffset() * 60000 + (5 * 60 + 45) * 60000)
    readonly property string kathmanduStr: Qt.formatDateTime(kathmanduDate, Units.twelveHourClock ? "h:mm A" : "hh:mm")

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Tokens.sizes.dashboard.dateTimeWidth

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        StyledText {
            Layout.bottomMargin: -(font.pointSize * 0.4)
            Layout.alignment: Qt.AlignHCenter
            text: Time.hourStr
            color: Colours.palette.m3secondary
            font: Tokens.font.clock.size(28).weight(Font.DemiBold).build()
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "•••"
            color: Colours.palette.m3primary
            font: Tokens.font.clock.size(28 * 0.9).build()
        }

        StyledText {
            Layout.topMargin: -(font.pointSize * 0.4)
            Layout.alignment: Qt.AlignHCenter
            text: Time.minuteStr
            color: Colours.palette.m3secondary
            font: Tokens.font.clock.size(28).weight(Font.DemiBold).build()
        }

        Loader {
            Layout.topMargin: -(((item as StyledText)?.font.pointSize ?? 0) * 0.4)
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: Config.dashboard.showClockSeconds
            visible: active

            sourceComponent: StyledText {
                text: "•••"
                color: Colours.palette.m3primary
                font: Tokens.font.clock.size(28 * 0.9).build()
            }
        }
        Loader {
            Layout.topMargin: -(((item as StyledText)?.font.pointSize ?? 0) * 0.4)
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: Config.dashboard.showClockSeconds
            visible: active

            sourceComponent: StyledText {
                text: Time.format("ss")
                color: Colours.palette.m3secondary
                font: Tokens.font.clock.size(28).weight(Font.DemiBold).build()
            }
        }

        Loader {
            asynchronous: true
            Layout.alignment: Qt.AlignHCenter

            active: Units.twelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Time.amPmStr
                color: Colours.palette.m3primary
                font: Tokens.font.clock.size(18).weight(Font.DemiBold).build()
            }
        }

        StyledRect {
            Layout.topMargin: Tokens.spacing.medium
            Layout.bottomMargin: Tokens.spacing.small
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colours.mutedLine
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                text: "public"
                color: Colours.mutedText
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                text: Tr.tr("Kathmandu")
                color: Colours.mutedText
                font: Tokens.font.label.small
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.extraSmall / 2

            animate: true
            text: root.kathmanduStr
            color: Colours.palette.m3secondary
            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
        }
    }
}
