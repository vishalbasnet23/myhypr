import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "root:/modules/common"
import "root:/modules/drawers"
import ".."

/**
 * Network: interface, address, and live throughput.
 *
 * Reads `ip -j addr` once per open rather than polling - an address does not
 * change while a popout is on screen, and DESIGN.md §13 requires a closed
 * panel to cost nothing. Rates come from the existing NetworkSpeed module's
 * /proc/net/dev reader, which is already running for the bar.
 */
ColumnLayout {
    id: root

    property int preferredWidth: 280
    /// Supplied by the bar module that owns this popout.
    property var source: null

    spacing: Glass.spaceS

    property string ipAddr: ""
    property string ifaceName: ""

    Process {
        id: probe

        running: true
        command: ["sh", "-c", "ip -4 -o addr show scope global | head -1 | awk '{print $2\" \"$4}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(/\s+/);
                if (parts.length >= 2) {
                    root.ifaceName = parts[0];
                    root.ipAddr = parts[1].split("/")[0];
                }
            }
        }
    }

    PopoutHeader {
        text: "Network"
    }

    BarText {
        text: root.source?.connected ? (root.ifaceName !== "" ? root.ifaceName : root.source.iface) : "Disconnected"
        color: root.source?.connected ? Glass.accent : Glass.critical
        pixelSize: Glass.fontBig
        elide: Text.ElideRight
        Layout.fillWidth: true
    }

    BarText {
        text: root.ipAddr !== "" ? root.ipAddr : "No address"
        color: Glass.textDim
        pixelSize: Glass.fontMeta
    }

    Card {
        Layout.fillWidth: true
        Layout.topMargin: Glass.spaceXs
        implicitHeight: rates.implicitHeight + Glass.cardPadding * 2

        ColumnLayout {
            id: rates

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Glass.spaceXs

            PopoutRow {
                label: "Down"
                icon: String.fromCodePoint(0xF13A)
                value: root.source ? root.source.human(root.source.down) : "--"
            }

            PopoutRow {
                label: "Up"
                icon: String.fromCodePoint(0xF139)
                value: root.source ? root.source.human(root.source.up) : "--"
            }
        }
    }
}
