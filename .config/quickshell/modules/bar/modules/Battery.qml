import QtQuick
import Quickshell.Services.UPower
import "root:/modules/common"
import "../popouts"
import ".."

/**
 * waybar battery module. Icon ramp, states and formats from Modules:
 *   format         "{icon} {capacity}%"
 *   format-charging " {capacity}%"
 *   states          good 95 / warning 30 / critical 15
 */
BarItem {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property int pct: Math.round((dev?.percentage ?? 0) * 100)
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
    readonly property var icons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    visible: dev?.isLaptopBattery ?? false

    // Detail popout: level, time remaining, power-profile selector.
    popoutId: "battery"
    popout: Component {
        BatteryPopout {}
    }

    BarText {
        text: root.charging ? ` ${root.pct}%` : `${root.icons[Math.min(10, Math.floor(root.pct / 10))]} ${root.pct}%`
        // Glass.css: .critical / .warning recolour the battery module
        color: root.pct <= 15 ? Glass.critical : root.pct <= 30 ? Glass.warn : Glass.textGlass
    }
}
