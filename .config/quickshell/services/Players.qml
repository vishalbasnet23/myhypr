pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

/**
 * The active MPRIS player.
 *
 * Picks the first player that is actually playing, falling back to the first
 * that exists, so the bar follows whatever you last started rather than
 * whichever client happened to register first.
 *
 * The position ticker is the important part: MPRIS `position` is a pull
 * property - it does NOT emit changes as playback advances. Without something
 * poking positionChanged() on an interval, a seek bar bound to it renders once
 * and then sits frozen for the whole track. (Approach borrowed from
 * caelestia-dots/shell, which solves it the same way.)
 */
Singleton {
    id: root

    readonly property var all: Mpris.players?.values ?? []

    readonly property MprisPlayer active: {
        const list = root.all;
        if (list.length === 0)
            return null;
        return list.find(p => p.isPlaying) ?? list[0];
    }

    readonly property bool hasPlayer: active !== null
    readonly property bool playing: active?.isPlaying ?? false

    readonly property string title: active?.trackTitle ?? ""
    readonly property string artist: active?.trackArtist ?? ""
    readonly property string album: active?.trackAlbum ?? ""
    readonly property string artUrl: active?.trackArtUrl ?? ""
    readonly property string identity: active?.identity ?? ""

    readonly property real position: active?.position ?? 0
    readonly property real length: active?.length ?? 0
    // Some players report a nonsense length for streams.
    readonly property bool lengthKnown: length > 0 && length < 2147483647
    readonly property real progress: lengthKnown ? Math.min(1, position / length) : 0

    function toggle() {
        if (active?.canTogglePlaying)
            active.togglePlaying();
    }

    function next() {
        if (active?.canGoNext)
            active.next();
    }

    function previous() {
        if (active?.canGoPrevious)
            active.previous();
    }

    function seekFraction(f) {
        if (active && root.lengthKnown && active.canSeek)
            active.position = Math.max(0, Math.min(root.length, f * root.length));
    }

    function timeStr(seconds) {
        if (!isFinite(seconds) || seconds < 0)
            return "--:--";
        const total = Math.floor(seconds);
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;
        const ss = s < 10 ? `0${s}` : `${s}`;
        if (h > 0)
            return `${h}:${m < 10 ? "0" + m : m}:${ss}`;
        return `${m}:${ss}`;
    }

    // Only tick while something is actually playing - no point waking up once
    // a second to re-read a paused position.
    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        onTriggered: root.active?.positionChanged()
    }
}
