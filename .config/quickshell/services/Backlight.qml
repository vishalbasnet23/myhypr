pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Screen backlight, for the waybar `backlight` module.
 *
 * Reads /sys/class/backlight/<dev>/{brightness,max_brightness} directly -
 * those are world-readable, so no helper is needed to DISPLAY the level.
 *
 * WRITING is different: brightness is root-owned (0644) on this machine, so
 * setting it goes through `brightnessctl`, exactly as scripts/Brightness.sh
 * does. brightnessctl ships a udev rule granting the video group access.
 * It was NOT installed before caelestia pulled it in, which is why the waybar
 * scroll binds on this module have been silently dead.
 */
Singleton {
    id: root

    readonly property string device: "intel_backlight"
    property int raw: 0
    property int max: 1
    readonly property int percent: max > 0 ? Math.round((raw / max) * 100) : 0
    readonly property bool writable: setter.available

    // backlight format-icons, by codepoint (the literals were empty):
    // U+E3D5 U+E3D7 U+E3DA then U+F00DD..U+F00E0
    readonly property var icons: [String.fromCodePoint(0xE3D5), String.fromCodePoint(0xE3D7), String.fromCodePoint(0xE3DA), String.fromCodePoint(0xF00DD), String.fromCodePoint(0xF00DE), String.fromCodePoint(0xF00DF), String.fromCodePoint(0xF00E0)]
    readonly property string icon: icons[Math.min(icons.length - 1, Math.floor((percent / 100) * icons.length))]

    function set(pct) {
        const clamped = Math.max(1, Math.min(100, Math.round(pct)));
        setter.command = ["brightnessctl", "-d", root.device, "set", `${clamped}%`];
        setter.running = true;
    }

    function step(delta) {
        set(root.percent + delta);
    }

    FileView {
        id: current

        path: `/sys/class/backlight/${root.device}/brightness`
        blockLoading: true
        watchChanges: true
        onFileChanged: root.raw = parseInt(text()) || 0
        Component.onCompleted: root.raw = parseInt(text()) || 0
    }

    FileView {
        id: maximum

        path: `/sys/class/backlight/${root.device}/max_brightness`
        blockLoading: true
        Component.onCompleted: root.max = parseInt(text()) || 1
    }

    Process {
        id: setter

        property bool available: true

        onExited: code => {
            // 127 == not found; stop pretending the control works.
            if (code === 127)
                available = false;
            current.reload();
            root.raw = parseInt(current.text()) || root.raw;
        }
    }

    // waybar polls this module every 2s; the FileView watch covers external
    // changes, this covers drivers that do not emit inotify events.
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            current.reload();
            root.raw = parseInt(current.text()) || root.raw;
        }
    }
}
