import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "root:/modules/common"
import ".."

/**
 * waybar group/audio = pulseaudio + pulseaudio#microphone.
 *
 * Volume changes go through scripts/Volume.sh so the OSD notification the
 * rest of the desktop shows stays identical; the displayed value comes from
 * Pipewire directly so it tracks changes made anywhere.
 */
BarItem {
    id: root

    property bool mic: false
    readonly property string home: Quickshell.env("HOME")
    readonly property PwNode node: mic ? Pipewire.defaultAudioSource : Pipewire.defaultAudioSink
    readonly property int volume: Math.round((node?.audio?.volume ?? 0) * 100)
    readonly property bool muted: node?.audio?.muted ?? false

    // pulseaudio format-icons from .config/waybar/Modules, by codepoint.
    // The literals here were empty strings - three of the four sink icons and
    // the mic icon had been lost entirely, which is why the module showed a
    // bare percentage.
    //   default ramp U+F026 U+F027 U+F057E U+F028
    //   muted U+F0581 | headphone U+F025 | headset U+F590
    //   phone/portable U+F095 | car U+F1B9 | bluetooth U+F00B0
    //   mic U+F130, muted U+F131
    readonly property var sinkIcons: [String.fromCodePoint(0xF026), String.fromCodePoint(0xF027), String.fromCodePoint(0xF057E), String.fromCodePoint(0xF028)]
    readonly property string iconMuted: String.fromCodePoint(0xF0581)
    readonly property string iconMic: String.fromCodePoint(0xF130)
    readonly property string iconMicMuted: String.fromCodePoint(0xF131)
    readonly property string iconBluetooth: String.fromCodePoint(0xF00B0)

    // Port-specific icons, matched the way waybar matches them.
    readonly property var portIcons: ({
            "headphone": String.fromCodePoint(0xF025),
            "hands-free": String.fromCodePoint(0xF025),
            "headset": String.fromCodePoint(0xF590),
            "phone": String.fromCodePoint(0xF095),
            "portable": String.fromCodePoint(0xF095),
            "car": String.fromCodePoint(0xF1B9)
        })

    function portIcon() {
        const d = `${root.node?.description ?? ""} ${root.node?.name ?? ""}`.toLowerCase();
        for (const key in root.portIcons)
            if (d.includes(key.replace("-", " ")) || d.includes(key))
                return root.portIcons[key];
        return "";
    }

    PwObjectTracker {
        objects: [root.node]
    }

    function vol(arg) {
        Quickshell.execDetached(["bash", `${root.home}/.config/hypr/scripts/Volume.sh`, arg]);
    }

    onClicked: button => {
        if (button === Qt.RightButton)
            Quickshell.execDetached(["pavucontrol", "-t", root.mic ? "4" : "3"]);
        else
            root.vol(root.mic ? "--toggle-mic" : "--toggle");
    }

    onScrolled: delta => {
        if (root.mic)
            root.vol(delta > 0 ? "--mic-inc" : "--mic-dec");
        else
            root.vol(delta > 0 ? "--inc" : "--dec");
    }

    BarText {
        text: {
            if (root.mic)
                return root.muted ? root.iconMicMuted : `${root.iconMic} ${root.volume}%`;
            if (root.muted)
                return root.iconMuted;
            // A recognised port wins over the generic volume ramp, which is
            // what waybar does with its headphone/headset/car icons.
            const port = root.portIcon();
            const i = Math.min(3, Math.floor((root.volume / 100) * 4));
            return `${port !== "" ? port : root.sinkIcons[i]} ${root.volume}%`;
        }
        color: root.muted ? Glass.textDim : Glass.textGlass
    }
}
