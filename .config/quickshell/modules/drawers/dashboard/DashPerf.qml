import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "root:/modules/common"
import "root:/modules/bar"
import "root:/modules/drawers"
import "root:/services"

/**
 * One full-width card per metric, ring on the left and label beside it -
 * the reference's layout, rather than the row of three rings I had first.
 *
 * GPU: no amdgpu `gpu_busy_percent` node exists on this machine, so the card
 * is driven by `nvidia-smi` and hides entirely when that returns nothing,
 * instead of showing a permanently empty ring.
 */
Item {
    id: root

    property int gpuUtil: -1
    readonly property bool hasGpu: gpuUtil >= 0

    Process {
        id: gpu

        command: ["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text.trim().split("\n")[0]);
                root.gpuUtil = isNaN(v) ? -1 : v;
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: gpu.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Glass.cardGap

        MetricCard {
            label: "CPU"
            value: SysMon.cpuUsage / 100
            text: `${Math.round(SysMon.cpuUsage)}%`
            detail: `${SysMon.tempC}°C`
            critical: SysMon.cpuUsage > 85
        }

        MetricCard {
            label: "Memory"
            value: SysMon.memTotalGb > 0 ? SysMon.memUsedGb / SysMon.memTotalGb : 0
            text: `${SysMon.memPercent}%`
            detail: `${SysMon.memUsedGb.toFixed(1)} / ${SysMon.memTotalGb.toFixed(1)} G`
            critical: SysMon.memPercent > 85
        }

        MetricCard {
            label: "Disk"
            value: SysMon.diskPercent / 100
            text: `${SysMon.diskPercent}%`
            detail: `${SysMon.diskUsedGb.toFixed(0)} / ${SysMon.diskTotalGb.toFixed(0)} G`
            critical: SysMon.diskPercent > 90
        }

        MetricCard {
            visible: root.hasGpu
            label: "GPU"
            value: root.gpuUtil / 100
            text: `${root.gpuUtil}%`
            critical: false
        }

        Item {
            Layout.fillHeight: true
        }
    }

    component MetricCard: Card {
        id: card

        property string label: ""
        property string text: ""
        property string detail: ""
        property real value: 0
        property bool critical: false

        Layout.fillWidth: true
        implicitHeight: 86

        RowLayout {
            anchors.fill: parent
            spacing: Glass.spaceM

            Ring {
                value: card.value
                label: card.text
                accent: card.critical ? Glass.critical : Glass.accent
                implicitWidth: 58
                implicitHeight: 58
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                // fillWidth on the TEXTS as well - a ColumnLayout centres any
                // child that does not fill, so without this each label sat at
                // a different x depending on its own width.
                BarText {
                    text: card.label
                    color: Glass.textGlass
                    pixelSize: Glass.fontTitle
                    horizontalAlignment: Text.AlignLeft
                    Layout.fillWidth: true
                }

                BarText {
                    text: card.detail
                    color: Glass.textDim
                    pixelSize: Glass.fontMeta
                    visible: text !== ""
                    horizontalAlignment: Text.AlignLeft
                    Layout.fillWidth: true
                }
            }
        }
    }
}
