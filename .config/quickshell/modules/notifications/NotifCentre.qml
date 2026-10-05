pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Open/closed state for the notification centre, plus the IPC that replaces
 * `swaync-client -t -sw` / `-d -sw` in keybinds and scripts.
 *
 *   qs ipc call notifs toggle     (was: swaync-client -t -sw)
 *   qs ipc call notifs dnd        (was: swaync-client -d -sw)
 *   qs ipc call notifs clear
 */
Singleton {
    id: root

    property bool open: false

    function toggle() {
        root.open = !root.open;
    }

    IpcHandler {
        target: "notifs"

        function toggle(): string {
            root.toggle();
            return root.open ? "open" : "closed";
        }

        function open(): string {
            root.open = true;
            return "open";
        }

        function close(): string {
            root.open = false;
            return "closed";
        }

        function dnd(): string {
            Notifs.toggleDnd();
            return Notifs.dnd ? "dnd on" : "dnd off";
        }

        function clear(): string {
            Notifs.clearAll();
            return "cleared";
        }

        function count(): int {
            return Notifs.count;
        }
    }
}
