import QtQuick
import Quickshell.Services.UPower
import "root:/modules/common"
import ".."

/**
 * waybar power-profiles-daemon module.
 *
 * KNOWN DEAD ON THIS MACHINE: power-profiles-daemon.service is masked
 * (/etc/systemd/system/power-profiles-daemon.service -> /dev/null) because TLP
 * is active and the two conflict. So PowerProfiles.profile never resolves and
 * this module hides itself, instead of showing a permanently wrong icon the
 * way the waybar version does.
 *
 * Unmasking ppd would mean disabling TLP - a power-management decision, not a
 * bar decision, so it is deliberately left alone.
 *
 * Also note: like custom/claudebar, this module has NO Glass.css rule, so it
 * renders unstyled in waybar today.
 */
BarItem {
    id: root

    // power-profiles-daemon format-icons, by codepoint (the literals were
    // empty): performance U+F0E7, balanced U+F24E, power-saver U+F06C
    readonly property var icons: ({
            "Performance": String.fromCodePoint(0xF0E7),
            "Balanced": String.fromCodePoint(0xF24E),
            "PowerSaver": String.fromCodePoint(0xF06C)
        })

    // PowerProfiles.profile is meaningless when the daemon cannot start.
    visible: PowerProfiles.profile !== undefined && daemonUp

    // If the service is masked, quickshell logs a D-Bus ServiceUnknown at
    // startup and the profile stays at its default forever.
    property bool daemonUp: false

    Component.onCompleted: daemonUp = PowerProfiles.hasPerformanceProfile || PowerProfiles.profile !== undefined

    BarText {
        text: `${root.icons[PowerProfile.toString(PowerProfiles.profile)] ?? ""} `
    }
}
