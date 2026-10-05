pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * CPU / memory / disk / temperature, feeding the mobo_drawer modules.
 *
 * Everything except disk comes from procfs and sysfs through blocking FileView
 * reads - these are page-cache reads of a few hundred bytes, far cheaper than
 * spawning `cat` once a second the way a waybar custom module would.
 *
 * Intervals match .config/waybar/Modules exactly: cpu 1s, memory 10s,
 * temperature 10s, disk 30s.
 */
Singleton {
    id: root

    // cpu
    property real cpuUsage: 0
    property var _prevCpu: null

    // memory - waybar prints "{used:0.1f}G", i.e. MemTotal - MemAvailable
    property real memUsedGb: 0
    property real memTotalGb: 0
    property int memPercent: 0

    // temperature - hwmon-path list from Modules, first readable wins
    property int tempC: 0
    readonly property int tempCritical: 82

    // disk - "/" only, as configured
    property int diskPercent: 0
    property real diskUsedGb: 0
    property real diskTotalGb: 0

    FileView {
        id: statFile

        path: "/proc/stat"
        blockLoading: true
    }

    FileView {
        id: memFile

        path: "/proc/meminfo"
        blockLoading: true
    }

    FileView {
        id: tempFile

        // Same order as waybar's hwmon-path array.
        path: "/sys/class/hwmon/hwmon1/temp1_input"
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: tempFallback

        path: "/sys/class/thermal/thermal_zone0/temp"
        blockLoading: true
        printErrors: false
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            const line = statFile.text().split("\n")[0];
            const f = line.trim().split(/\s+/).slice(1).map(Number);
            if (f.length < 4)
                return;
            const idle = f[3] + (f[4] ?? 0);
            const total = f.reduce((a, b) => a + b, 0);
            if (root._prevCpu) {
                const dTotal = total - root._prevCpu.total;
                const dIdle = idle - root._prevCpu.idle;
                if (dTotal > 0)
                    root.cpuUsage = Math.max(0, Math.min(100, (1 - dIdle / dTotal) * 100));
            }
            root._prevCpu = {
                total: total,
                idle: idle
            };
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            memFile.reload();
            let total = 0;
            let avail = 0;
            for (const l of memFile.text().split("\n")) {
                const m = l.match(/^(MemTotal|MemAvailable):\s+(\d+) kB/);
                if (!m)
                    continue;
                if (m[1] === "MemTotal")
                    total = parseInt(m[2]);
                else
                    avail = parseInt(m[2]);
            }
            if (total > 0) {
                root.memTotalGb = total / 1024 / 1024;
                root.memUsedGb = (total - avail) / 1024 / 1024;
                root.memPercent = Math.round(((total - avail) / total) * 100);
            }

            tempFile.reload();
            let raw = parseInt(tempFile.text());
            if (isNaN(raw)) {
                tempFallback.reload();
                raw = parseInt(tempFallback.text());
            }
            if (!isNaN(raw))
                root.tempC = Math.round(raw / 1000);
        }
    }

    // statvfs has no QML binding, so this is the one place a process is needed.
    Process {
        id: df

        command: ["df", "-B1", "--output=used,size", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = this.text.trim().split("\n");
                if (rows.length < 2)
                    return;
                const [used, size] = rows[1].trim().split(/\s+/).map(Number);
                if (size > 0) {
                    root.diskUsedGb = used / 1e9;
                    root.diskTotalGb = size / 1e9;
                    root.diskPercent = Math.round((used / size) * 100);
                }
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }
}
