pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    // QML-only workspace indicator styles layered on top of the native
    // Shapes/Text/Icons displayType (Caelestia.Config BarWorkspaceDisplay).
    // "none" defers entirely to the native displayType. Persisted outside
    // the C++-backed shell.json schema so adding styles never needs a
    // plugin rebuild.
    readonly property list<string> styles: ["none", "dots", "pill", "segments", "ticks", "bracket", "badge", "glow", "braille", "underline", "ring", "trail"]

    property string style: "none"
    property bool loaded: false

    onStyleChanged: {
        if (!loaded)
            return;
        storage.setText(JSON.stringify({
            style
        }));
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.config}/workspace-style.json`

        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (typeof data.style === "string" && root.styles.includes(data.style))
                    root.style = data.style;
            } catch (error) {
                console.warn(lc, `Unable to parse workspace style: ${error}`);
            }
            root.loaded = true;
        }

        onLoadFailed: err => {
            root.loaded = true;
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText(JSON.stringify({
                    style: root.style
                })));
            else
                console.warn(lc, `Unable to load workspace style: ${err}`);
        }
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.services.workspaceExtra"
        defaultLogLevel: LoggingCategory.Info
    }
}
