import QtQuick
import QtQuick.Layouts
import "root:/modules/common"
import "root:/services"
import ".."

/**
 * Replaces waybar's group/mobo_drawer.
 *
 * The drawer could only reveal four more cramped labels in a row. With the
 * space a popout gives, each reading gets a meter, and the tooltips that were
 * hidden behind a hover in waybar ("{used:0.1f}GB/{total:0.1f}G", "{used} used
 * out of {total} on {path}") become visible text.
 */
ColumnLayout {
    id: root

    spacing: 9
    // Layouts clobber implicitWidth, so the panel reads this instead.
    property int preferredWidth: 400

    PopoutHeader {
        text: "System"
    }

    PopoutRow {
        label: "CPU"
        icon: "󰍛"
        value: `${Math.round(SysMon.cpuUsage)}%`
        fraction: SysMon.cpuUsage / 100
        meterColour: SysMon.cpuUsage > 85 ? Glass.critical : Glass.accent
    }

    PopoutRow {
        label: "Memory"
        icon: "󰾆"
        value: `${SysMon.memUsedGb.toFixed(1)}/${SysMon.memTotalGb.toFixed(1)}G`
        fraction: SysMon.memTotalGb > 0 ? SysMon.memUsedGb / SysMon.memTotalGb : 0
        meterColour: SysMon.memPercent > 85 ? Glass.critical : Glass.accent
    }

    PopoutRow {
        label: "Disk /"
        icon: "󰋊"
        value: `${SysMon.diskUsedGb.toFixed(0)}/${SysMon.diskTotalGb.toFixed(0)}G`
        fraction: SysMon.diskPercent / 100
        meterColour: SysMon.diskPercent > 90 ? Glass.critical : Glass.accent
    }

    PopoutRow {
        label: "Temp"
        icon: "󰈸"
        value: `${SysMon.tempC}°C`
        // Scaled against the critical threshold from Modules, not 100°C, so
        // the meter fills as the machine approaches the limit that matters.
        fraction: SysMon.tempC / SysMon.tempCritical
        meterColour: SysMon.tempC >= SysMon.tempCritical ? Glass.critical : SysMon.tempC > 70 ? Glass.warn : Glass.ok
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 3
        implicitHeight: 1
        color: Glass.glassBorder
    }

    BarText {
        text: "Right-click a module for nvtop · btop · system monitor"
        color: Glass.textDim
        pixelSize: Glass.fontMeta
    }
}
