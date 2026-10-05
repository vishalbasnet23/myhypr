import QtQuick
import Quickshell
import "root:/modules/common"
import "root:/services"
import ".."

/**
 * The four procfs-backed readouts from waybar's group/mobo_drawer, kept in one
 * file because they share a data source (services/SysMon.qml) and differ only
 * in format string and right-click target:
 *
 *   temperature  "{temperatureC}°C 󰈸"   right -> WaybarScripts.sh --nvtop
 *   cpu          "{usage}% 󰍛"            right -> gnome-system-monitor
 *   memory       "{used:0.1f}G 󰾆"        right -> WaybarScripts.sh --btop
 *   disk         "{percentage_used}% 󰋊"
 *
 * `kind` picks which one this instance is.
 */
BarItem {
    id: root

    /// "temperature" | "cpu" | "memory" | "disk"
    property string kind: "cpu"

    readonly property string home: Quickshell.env("HOME")
    readonly property bool critical: kind === "temperature" && SysMon.tempC >= SysMon.tempCritical

    onClicked: button => {
        if (button !== Qt.RightButton)
            return;
        if (kind === "temperature")
            Quickshell.execDetached(["bash", `${root.home}/.config/hypr/scripts/WaybarScripts.sh`, "--nvtop"]);
        else if (kind === "cpu")
            Quickshell.execDetached(["gnome-system-monitor"]);
        else if (kind === "memory")
            Quickshell.execDetached(["bash", `${root.home}/.config/hypr/scripts/WaybarScripts.sh`, "--btop"]);
    }

    BarText {
        text: {
            switch (root.kind) {
            case "temperature":
                return `${SysMon.tempC}°C 󰈸`;
            case "cpu":
                return `${Math.round(SysMon.cpuUsage)}% 󰍛`;
            case "memory":
                return `${SysMon.memUsedGb.toFixed(1)}G 󰾆`;
            case "disk":
                return `${SysMon.diskPercent}% 󰋊`;
            }
            return "";
        }
        // Glass.css .critical turns the temperature module red past 82°C
        color: root.critical ? Glass.critical : Glass.textGlass
    }
}
