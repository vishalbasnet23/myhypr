pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

/**
 * Per-screen open/closed flags for every drawer panel.
 *
 * Panels exist on all screens, but only one screen's copy is ever open - the
 * focused one - so the state is keyed by monitor name rather than duplicated
 * per Variants instance. A panel asks `ShellState.isOpen("dashboard", screen)`.
 *
 * Every toggle is exposed over IPC (target "panels") so keybinds go through
 * `qs ipc call panels dashboard` rather than each panel inventing its own
 * mechanism.
 */
Singleton {
    id: root

    readonly property var names: ["dashboard", "launcher", "sidebar", "session", "osd"]

    /// { dashboard: "DP-2", launcher: "", … } - which screen has it open, "" = closed.
    property var openOn: ({
            dashboard: "",
            launcher: "",
            sidebar: "",
            session: "",
            osd: ""
        })

    /// Bumped on every change; panels depend on it so plain-object mutation
    /// still triggers their bindings.
    property int revision: 0

    /// Dashboard tab index. Lives here rather than inside DashTabs so it
    /// survives a close/open and can be driven over IPC.
    property int dashboardTab: 0

    function focusedName() {
        return Hyprland.focusedMonitor?.name ?? "";
    }

    function isOpen(name, screenName) {
        return root.openOn[name] === screenName && screenName !== "";
    }

    function anyOpen(screenName) {
        for (const n of root.names)
            if (root.isOpen(n, screenName))
                return true;
        return false;
    }

    function open(name, screenName) {
        const s = screenName ?? root.focusedName();
        root.openOn[name] = s;
        root.revision++;
    }

    function close(name) {
        root.openOn[name] = "";
        root.revision++;
    }

    function toggle(name, screenName) {
        const s = screenName ?? root.focusedName();
        if (root.openOn[name] === s)
            root.close(name);
        else
            root.open(name, s);
        return root.openOn[name] !== "";
    }

    function closeAll() {
        for (const n of root.names)
            root.openOn[n] = "";
        root.revision++;
    }

    IpcHandler {
        target: "panels"

        function dashboard(): string {
            return ShellState.toggle("dashboard") ? "open" : "closed";
        }

        function launcher(): string {
            return ShellState.toggle("launcher") ? "open" : "closed";
        }

        function sidebar(): string {
            return ShellState.toggle("sidebar") ? "open" : "closed";
        }

        function session(): string {
            return ShellState.toggle("session") ? "open" : "closed";
        }

        function osd(): string {
            return ShellState.toggle("osd") ? "open" : "closed";
        }

        function close(): string {
            ShellState.closeAll();
            return "closed";
        }

        function tab(index: int): string {
            if (index < 0 || index > 3)
                return "tab must be 0-3";
            ShellState.dashboardTab = index;
            return `tab ${index}`;
        }

        function status(): string {
            const out = [];
            for (const n of ShellState.names)
                if (ShellState.openOn[n] !== "")
                    out.push(`${n}@${ShellState.openOn[n]}`);
            return out.length > 0 ? out.join(" ") : "none";
        }
    }
}
