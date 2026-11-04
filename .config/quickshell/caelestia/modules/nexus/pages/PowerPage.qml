pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property int lockIdx: Config.general.idle.timeouts.values.findIndex(e => e.idleAction === "lock")
    readonly property int screenOffIdx: Config.general.idle.timeouts.values.findIndex(e => e.idleAction === "dpms off")
    readonly property int suspendIdx: Config.general.idle.timeouts.values.findIndex(e => Array.isArray(e.idleAction) && e.idleAction.includes("suspendThenHibernate"))

    function minutesAt(index: int): int {
        return index >= 0 ? Math.max(1, Math.round(Config.general.idle.timeouts.values[index].timeout / 60)) : 0;
    }

    function setMinutesAt(index: int, minutes: int): void {
        if (index >= 0)
            GlobalConfig.general.idle.timeouts.at(index).timeout = minutes * 60;
    }

    title: Tr.tr("Power")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Idle timeouts
        SectionHeader {
            first: true
            text: Tr.tr("Idle timeouts")
        }

        StepperRow {
            first: true
            label: Tr.tr("Lock after")
            subtext: Tr.tr("Minutes of inactivity before the screen locks")
            value: root.minutesAt(root.lockIdx)
            from: 1
            to: 180
            stepSize: 1
            enabled: root.lockIdx >= 0
            onMoved: v => root.setMinutesAt(root.lockIdx, v)
        }

        StepperRow {
            label: Tr.tr("Screen off after")
            subtext: Tr.tr("Minutes of inactivity before the display turns off")
            value: root.minutesAt(root.screenOffIdx)
            from: 1
            to: 180
            stepSize: 1
            enabled: root.screenOffIdx >= 0
            onMoved: v => root.setMinutesAt(root.screenOffIdx, v)
        }

        StepperRow {
            last: true
            label: Tr.tr("Suspend after")
            subtext: Tr.tr("Minutes of inactivity before the system suspends")
            value: root.minutesAt(root.suspendIdx)
            from: 1
            to: 360
            stepSize: 5
            enabled: root.suspendIdx >= 0
            onMoved: v => root.setMinutesAt(root.suspendIdx, v)
        }

        // Behaviour
        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Lock before sleep")
            subtext: Tr.tr("Always lock the screen before the system suspends")
            checked: Config.general.idle.lockBeforeSleep
            onToggled: GlobalConfig.general.idle.lockBeforeSleep = checked
        }

        ToggleRow {
            text: Tr.tr("Pause while audio is playing")
            subtext: Tr.tr("Don't lock, dim, or suspend while something is playing audio")
            checked: Config.general.idle.inhibitWhenAudio
            onToggled: GlobalConfig.general.idle.inhibitWhenAudio = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Pause while charging")
            subtext: Tr.tr("Don't lock, dim, or suspend while plugged in")
            checked: Config.general.idle.inhibitWhenCharging
            onToggled: GlobalConfig.general.idle.inhibitWhenCharging = checked
        }
    }
}
