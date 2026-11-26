pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Battery facts UPower doesn't expose (design capacity, cycle count, charge
// thresholds), read straight from sysfs. sysfs attributes don't emit inotify
// events, so consumers call refresh() when they are created.
Singleton {
    id: root

    property bool available: false
    property string batteryName: ""
    property real energyFullWh: 0
    property real energyDesignWh: 0
    property int cycleCount: 0
    property int startThreshold: -1
    property int endThreshold: -1

    readonly property real health: energyDesignWh > 0 ? energyFullWh / energyDesignWh : 0
    readonly property bool thresholdsSupported: endThreshold >= 0

    // Charge-limit presets. Each `tlp setcharge <start> <stop> BAT0` must match
    // a NOPASSWD entry in /etc/sudoers.d/50-tlp-charge-limit exactly (copy in
    // .config/quickshell/battery/), or sudo -n refuses.
    readonly property var chargePresets: [
        {
            stop: 100,
            start: 0
        },
        {
            stop: 90,
            start: 85
        },
        {
            stop: 80,
            start: 75
        }
    ]
    property bool settingLimit: false
    property bool refreshPending: false

    function refresh(): void {
        if (readProc.running)
            refreshPending = true;
        else
            readProc.running = true;
    }

    // Temporary until reboot / TLP restart; /etc/tlp.d/20-battery.conf wins at boot.
    function setChargeLimit(stop: int): void {
        const preset = chargePresets.find(p => p.stop === stop);
        if (!preset || !batteryName || setProc.running) {
            Quickshell.execDetached(["notify-send", "-u", "critical", "Charge limit", `Cannot set ${stop}% (battery: ${batteryName || "none"})`]);
            return;
        }
        settingLimit = true;
        setProc.command = ["sudo", "-n", "/usr/bin/tlp", "setcharge", `${preset.start}`, `${preset.stop}`, batteryName];
        setProc.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: readProc

        // First BAT* only; prints "name:BATn" then "attr:value" for whichever attributes exist.
        command: ["sh", "-c", "for d in /sys/class/power_supply/BAT*; do cd \"$d\" || exit; echo \"name:${d##*/}\"; grep -sH . energy_full energy_full_design charge_full charge_full_design voltage_min_design cycle_count charge_control_start_threshold charge_control_end_threshold; break; done"]

        onRunningChanged: {
            if (!running && root.refreshPending) {
                root.refreshPending = false;
                running = true;
            }
        }

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const v = {};
                let name = "";
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf(":");
                    if (i <= 0)
                        continue;
                    const key = line.slice(0, i);
                    if (key === "name")
                        name = line.slice(i + 1);
                    else
                        v[key] = parseInt(line.slice(i + 1));
                }

                // Some batteries report charge (µAh) instead of energy (µWh).
                const volts = (v.voltage_min_design ?? 0) / 1e6;
                const toWh = (energy, charge) => energy !== undefined ? energy / 1e6 : (charge !== undefined && volts > 0 ? charge / 1e6 * volts : 0);

                // Firmware uses 0 or >100 (e.g. 255) to mean "no limit".
                let end = v.charge_control_end_threshold ?? -1;
                if (end === 0 || end > 100)
                    end = 100;

                root.batteryName = name;
                root.energyFullWh = toWh(v.energy_full, v.charge_full);
                root.energyDesignWh = toWh(v.energy_full_design, v.charge_full_design);
                root.cycleCount = v.cycle_count ?? 0;
                root.startThreshold = v.charge_control_start_threshold ?? -1;
                root.endThreshold = end;
                root.available = name !== "";
            }
        }
    }

    Process {
        id: setProc

        stderr: StdioCollector {
            id: setErr

            waitForEnd: true
        }

        onExited: code => {
            root.settingLimit = false;
            root.refresh();
            if (code !== 0)
                Quickshell.execDetached(["notify-send", "-u", "critical", "Charge limit", `tlp setcharge failed (${code}): ${setErr.text.trim()}`]);
        }
    }
}
