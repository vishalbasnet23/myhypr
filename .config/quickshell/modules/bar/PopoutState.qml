pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "root:/modules/common"

/**
 * Which bar module currently owns the popout.
 *
 * Only one popout is ever open, because there is only one pointer - so this is
 * global state rather than per-screen. `screen` records which screen's popout
 * window should actually show it.
 *
 * The open/close delays exist to make the thing usable: without a close delay
 * the popout dies the instant the pointer leaves the module, including while
 * travelling the few pixels DOWN into the popout itself. `hold()` is what the
 * popout calls to say "the pointer is inside me, stay up".
 */
Singleton {
    id: root

    property Item anchorItem: null
    property Component content: null
    property var screen: null
    property string owner: ""

    readonly property bool open: content !== null

    // §8: 80ms to open, none when another popout is already open (it just
    // moves), 250ms to close so the pointer can cross the gap.
    readonly property int openDelay: Glass.popoutOpenDelay
    readonly property int closeDelay: Glass.popoutCloseDelay

    function request(id, item, component, scr) {
        closeTimer.stop();
        pending.id = id;
        pending.item = item;
        pending.component = component;
        pending.screen = scr;
        if (root.open)
            apply();        // already showing something: swap immediately
        else
            openTimer.restart();
    }

    function apply() {
        root.owner = pending.id;
        root.anchorItem = pending.item;
        root.content = pending.component;
        root.screen = pending.screen;
    }

    /// Called on pointer-exit from a module or the popout body.
    function release(id) {
        if (id !== "" && root.owner !== id && pending.id !== id)
            return;
        openTimer.stop();
        closeTimer.restart();
    }

    /// Called while the pointer is inside the popout body.
    function hold() {
        openTimer.stop();
        closeTimer.stop();
    }

    // ---- registry, so popouts can also be opened without a pointer ----
    // Keyed by popoutId; each entry is {item, component, screenFn}. This is
    // what lets a keybind or `qs ipc` open the calendar, and it is how the
    // panels can be exercised in a screenshot without moving the mouse.
    property var registry: ({})

    function register(id, item, component, screenFn) {
        const r = root.registry;
        if (!r[id])
            r[id] = [];
        r[id].push({
            item: item,
            component: component,
            screenFn: screenFn
        });
        root.registry = r;
    }

    function unregister(id) {
        const r = root.registry;
        if (r[id])
            r[id] = r[id].filter(e => e.item !== null);
        root.registry = r;
        if (root.owner === id)
            root.hide();
    }

    function show(id) {
        const entries = root.registry[id];
        if (!entries || entries.length === 0)
            return false;

        // Open on the monitor the user is actually looking at.
        const want = Hyprland.focusedMonitor?.name ?? "";
        let e = entries.find(x => x.screenFn()?.name === want) ?? entries[0];
        closeTimer.stop();
        openTimer.stop();
        root.owner = id;
        root.anchorItem = e.item;
        root.content = e.component;
        root.screen = e.screenFn();
        return true;
    }

    function hide() {
        openTimer.stop();
        closeTimer.stop();
        root.owner = "";
        root.content = null;
        root.anchorItem = null;
        root.screen = null;
    }

    function toggle(id) {
        if (root.owner === id) {
            root.hide();
            return false;
        }
        return root.show(id);
    }

    IpcHandler {
        target: "bar"

        function popout(name: string): string {
            return PopoutState.toggle(name) ? `opened ${name}` : `closed/unknown ${name}`;
        }

        function close(): string {
            PopoutState.hide();
            return "closed";
        }

        function list(): string {
            return Object.keys(PopoutState.registry).join(" ");
        }

        // Bar visibility - replaces `pkill -SIGUSR1 waybar`.
        function toggle(): string {
            BarState.toggle();
            return BarState.visible ? "shown" : "hidden";
        }

        function show(): string {
            BarState.visible = true;
            return "shown";
        }

        function hide(): string {
            BarState.visible = false;
            return "hidden";
        }
    }

    QtObject {
        id: pending

        property string id: ""
        property Item item: null
        property Component component: null
        property var screen: null
    }

    Timer {
        id: openTimer

        interval: root.openDelay
        onTriggered: root.apply()
    }

    Timer {
        id: closeTimer

        interval: root.closeDelay
        onTriggered: {
            root.owner = "";
            root.content = null;
            root.anchorItem = null;
            root.screen = null;
        }
    }
}
