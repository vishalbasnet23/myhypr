pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Tracks swaync's control center.
 *
 * `swaync-client -s` streams a JSON line whenever anything changes:
 *   { "count": 1, "dnd": false, "visible": false, "inhibited": false }
 * `visible` is the control center's open state, which is what the media card
 * follows so it can dock beside the panel.
 *
 * This exists because swaync's own mpris widget cannot be made to look like the
 * shell's media card — its widgets are compiled GTK with a fixed layout and no
 * seek bar, volume slider or art-derived colour. So that widget is switched off
 * in swaync's config and the real card is shown next to the panel instead.
 */
Singleton {
    id: root

    property bool controlCenterOpen: false
    property int notificationCount: 0
    property bool dnd: false

    Process {
        id: subscription
        running: true
        command: ["swaync-client", "-s"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line);
                    root.controlCenterOpen = data.visible === true;
                    root.notificationCount = data.count ?? 0;
                    root.dnd = data.dnd === true;
                } catch (e) {
                    // swaync prints non-JSON on startup occasionally; ignore.
                }
            }
        }
        // swaync restarts on Refresh.sh, which kills the subscription with it.
        onRunningChanged: if (!running)
            resubscribe.restart()
    }

    Timer {
        id: resubscribe
        interval: 2000
        onTriggered: subscription.running = true
    }
}
