pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils
import "ClipboardHistory.js" as ClipboardHistory

// Clipboard history backend, ported from the omacom/omarchy clipboard plugin
// (shell/plugins/clipboard). Capture runs continuously from shell init:
// wl-paste --watch feeds capture.sh, which emits JSON entries; images land in
// ${Paths.state}/clipboard/images/<sha256>.<ext>. History persists to
// ${Paths.state}/clipboard/history.json. UI lives in modules/clipboard/
// (picker), the bar status icon in StatusIcons.qml and its hover popout in
// modules/bar/popouts/ClipboardPopout.qml.

Singleton {
    id: root

    readonly property int historyLimit: 500
    readonly property string captureScript: `${Quickshell.shellDir}/modules/clipboard/capture.sh`
    readonly property string pasteScript: `${Quickshell.shellDir}/modules/clipboard/paste.sh`

    property var history: []
    readonly property int count: history.length

    function displayRows(query: string, limit: int): var {
        return ClipboardHistory.displayRows(root.history, query, limit);
    }

    function saveHistory(): void {
        storage.setText(JSON.stringify(root.history.slice(0, root.historyLimit), null, 2) + "\n");
    }

    function addClipboardEntry(entry: var): void {
        const normalized = ClipboardHistory.normalizeEntry(entry);
        if (!normalized)
            return;
        root.history = ClipboardHistory.addEntry(root.history, normalized, root.historyLimit);
        root.saveHistory();
    }

    function addClipboardJson(line: string): void {
        root.addClipboardEntry(ClipboardHistory.parseEntryJson(line));
    }

    function removeAt(historyIndex: int): void {
        root.history = ClipboardHistory.removeEntryAt(root.history, historyIndex);
        root.saveHistory();
    }

    function clearHistory(): void {
        root.history = [];
        root.saveHistory();
    }

    // row = a displayRows() row; its index addresses the full history entry.
    function paste(row: var): void {
        act("paste", row);
    }

    function copy(row: var): void {
        act("copy", row);
    }

    function openEntry(row: var): void {
        act("open", row);
    }

    function act(mode: string, row: var): void {
        if (!row)
            return;
        if (mode === "open")
            Quickshell.execDetached([root.pasteScript, "open", String(row.index)]);
        else if (row.entryType === "image")
            Quickshell.execDetached([root.pasteScript, `${mode}-image`, row.mime, row.path]);
        else if (row.fullText)
            Quickshell.execDetached([root.pasteScript, `${mode}-text`, String(row.index)]);
    }

    FileView {
        id: storage

        path: `${Paths.state}/clipboard/history.json`
        watchChanges: true
        atomicWrites: true
        printErrors: false

        onLoaded: root.history = ClipboardHistory.parseHistory(text())
        onLoadFailed: err => {
            root.history = [];
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText("[]"));
        }
        onFileChanged: reload()
    }

    // ---- capture pipeline ----
    // Reap watchers left behind by a previous shell instance, snapshot the
    // current clipboard once, then run the text and image watchers. The
    // pdeathsig makes the kernel kill the watchers whenever the shell exits,
    // however it exits, so no further lifecycle management is needed.

    Component.onCompleted: initProc.running = true

    Process {
        id: initProc

        command: ["pkill", "-f", "wl-paste .*--watch .*modules/clipboard/capture\\.sh"]
        onExited: {
            snapshotProc.running = true;
            textWatchProc.running = true;
            imageWatchProc.running = true;
        }
    }

    Process {
        id: snapshotProc

        command: [root.captureScript]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.addClipboardJson(text)
        }
    }

    Process {
        id: textWatchProc

        command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "text", "--watch", root.captureScript, "text"]
        onExited: watchRestartTimer.restart()

        stdout: SplitParser {
            onRead: data => root.addClipboardJson(data)
        }
    }

    Process {
        id: imageWatchProc

        command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "image/png", "--watch", root.captureScript, "image/png"]
        onExited: watchRestartTimer.restart()

        stdout: SplitParser {
            onRead: data => root.addClipboardJson(data)
        }
    }

    // A watcher that dies takes clipboard history with it silently: copying
    // still works and the picker still opens, but nothing gets recorded until
    // the next shell reload. Bring it back instead.
    Timer {
        id: watchRestartTimer

        interval: 1000
        repeat: false
        onTriggered: {
            if (!textWatchProc.running)
                textWatchProc.running = true;
            if (!imageWatchProc.running)
                imageWatchProc.running = true;
        }
    }
}
