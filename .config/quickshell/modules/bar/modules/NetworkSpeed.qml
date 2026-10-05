import QtQuick
import Quickshell.Io
import "root:/modules/common"
import "../popouts"
import ".."

/**
 * waybar network#speed-alt:
 *   format-wifi     "  {bandwidthDownBytes}"
 *   format-ethernet "󰌘  {bandwidthUpBytes} {bandwidthDownBytes}"
 *   format-disconnected "󰌙"
 *   interval 3
 *
 * NOTE: the format-ethernet string in .config/waybar/Modules is missing a
 * closing brace - "{bandwidthUpBytes  {bandwidthDownBytes}" - so waybar prints
 * it literally today. Fixed here.
 *
 * Rates come from /proc/net/dev deltas. Virtual interfaces are skipped, or the
 * docker bridges and veth pairs on this machine would dominate the numbers.
 */
BarItem {
    id: root

    property string iface: ""
    property bool wifi: false
    property real down: 0
    property real up: 0
    property bool connected: iface !== ""

    property var _prev: ({})
    property double _prevAt: 0

    function human(bytesPerSec) {
        const units = ["B", "kB", "MB", "GB"];
        let v = bytesPerSec;
        let i = 0;
        while (v >= 1000 && i < units.length - 1) {
            v /= 1000;
            i++;
        }
        return `${v < 10 && i > 0 ? v.toFixed(1) : Math.round(v)}${units[i]}/s`;
    }

    FileView {
        id: netdev

        path: "/proc/net/dev"
        blockLoading: true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            netdev.reload();
            const now = Date.now();
            const dt = root._prevAt > 0 ? (now - root._prevAt) / 1000 : 0;
            const cur = {};
            let bestIface = "";
            let bestTotal = -1;

            for (const line of netdev.text().split("\n")) {
                const m = line.match(/^\s*([\w-]+):\s*(\d+)(?:\s+\d+){7}\s+(\d+)/);
                if (!m)
                    continue;
                const name = m[1];
                // Skip loopback and the docker/veth zoo
                if (name === "lo" || name.startsWith("veth") || name.startsWith("br-") || name === "docker0")
                    continue;
                const rx = parseInt(m[2]);
                const tx = parseInt(m[3]);
                cur[name] = [rx, tx];
                if (rx + tx > bestTotal) {
                    bestTotal = rx + tx;
                    bestIface = name;
                }
            }

            if (bestIface && dt > 0 && root._prev[bestIface]) {
                root.down = Math.max(0, (cur[bestIface][0] - root._prev[bestIface][0]) / dt);
                root.up = Math.max(0, (cur[bestIface][1] - root._prev[bestIface][1]) / dt);
            }

            root.iface = bestIface;
            root.wifi = bestIface.startsWith("wl");
            root._prev = cur;
            root._prevAt = now;
        }
    }

    // Icons from .config/waybar/Modules, built by codepoint so a bad paste
    // cannot silently drop them (which is exactly what happened to the wifi
    // one - its branch had two spaces and no glyph at all):
    //   U+F13A  down arrow   U+F139 up arrow
    //   U+F0318 ethernet     U+F0319 disconnected
    readonly property string iconDown: String.fromCodePoint(0xF13A)
    readonly property string iconUp: String.fromCodePoint(0xF139)
    readonly property string iconEth: String.fromCodePoint(0xF0318)
    readonly property string iconOff: String.fromCodePoint(0xF0319)

    popoutId: "network"
    popout: Component {
        NetworkPopout {
            source: root
        }
    }

    BarText {
        text: {
            if (!root.connected)
                return root.iconOff;
            if (root.wifi)
                return `${root.iconDown} ${root.human(root.down)}`;
            return `${root.iconEth} ${root.iconUp} ${root.human(root.up)} ${root.iconDown} ${root.human(root.down)}`;
        }
        color: root.connected ? Glass.textGlass : Glass.textDim
    }
}
