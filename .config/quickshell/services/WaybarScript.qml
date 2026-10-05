import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Runs a script on an interval and parses waybar's custom-module contract:
 *
 *   return-type "json" -> { "text": …, "alt": …, "tooltip": …, "class": …,
 *                           "percentage": … }
 *   otherwise          -> the raw stdout, trimmed, becomes `text`
 *
 * This is what lets the bar keep using the existing UserScripts unchanged -
 * Weather.sh, PacmanUpdate.sh, MouseBattery.sh and claudebar all already speak
 * this format because waybar asked them to.
 *
 * `execIf` mirrors waybar's "exec-if": a non-zero exit means "no data this
 * round", and the module hides itself rather than showing a stale value.
 */
Item {
    id: root

    /// Command to run, as an argv list (NOT a shell string).
    property var command: []
    /// Optional gate command; when set, it must exit 0 before `command` runs.
    property var execIf: []
    /// Seconds between runs, matching waybar's `interval`.
    property int intervalSec: 60
    /// Parse stdout as JSON when true.
    property bool json: true
    /// Run once immediately on startup.
    property bool runOnStart: true

    readonly property string text: _text
    readonly property string alt: _alt
    readonly property string tooltip: _tooltip
    readonly property string cssClass: _class
    readonly property real percentage: _percentage
    /// False until the first successful run, so modules can stay hidden.
    readonly property bool valid: _valid

    property string _text: ""
    property string _alt: ""
    property string _tooltip: ""
    property string _class: ""
    property real _percentage: 0
    property bool _valid: false

    signal updated

    function refresh() {
        if (root.execIf.length > 0) {
            gate.running = true;
        } else {
            job.running = true;
        }
    }

    Process {
        id: gate
        command: root.execIf
        onExited: code => {
            if (code === 0)
                job.running = true;
            else
                root._valid = false;
        }
    }

    Process {
        id: job
        command: root.command
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = this.text.trim();
                if (raw.length === 0) {
                    root._valid = false;
                    return;
                }
                if (!root.json) {
                    root._text = raw;
                    root._tooltip = "";
                    root._class = "";
                    root._valid = true;
                    root.updated();
                    return;
                }
                try {
                    const d = JSON.parse(raw);
                    root._text = d.text ?? "";
                    root._alt = d.alt ?? "";
                    root._tooltip = d.tooltip ?? "";
                    // waybar allows "class" to be a string or a list
                    root._class = Array.isArray(d.class) ? (d.class[0] ?? "") : (d.class ?? "");
                    root._percentage = d.percentage ?? 0;
                    root._valid = true;
                    root.updated();
                } catch (e) {
                    // Treat unparseable output as "no data" rather than showing
                    // a JSON blob in the bar.
                    root._valid = false;
                }
            }
        }
    }

    Timer {
        interval: root.intervalSec * 1000
        running: true
        repeat: true
        triggeredOnStart: root.runOnStart
        onTriggered: root.refresh()
    }
}
