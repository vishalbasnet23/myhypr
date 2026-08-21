pragma Singleton
pragma ComponentBehavior: Bound

// Adapted from MainstreamOS/dots-hyprland (services/MprisController.qml), which
// took it from https://git.outfoxxed.me/outfoxxed/nixnew — no license, author is
// okay with redistribution.
//
// Trimmed for this config: the upstream version resolves browser MPRIS bridges
// (mpris-hyprland) through a helper script and /proc ancestry, and reads its
// options out of a 1183-line Config singleton. Neither exists here, so the
// player filtering is the plain kind: drop the playerctld mirror and the bare
// mpd bus, keep everything else.

import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    property list<MprisPlayer> players: Mpris.players.values.filter(player => root.isRealPlayer(player))
    property MprisPlayer trackedPlayer: null
    property MprisPlayer activePlayer: trackedPlayer ?? root.players[0] ?? null
    signal trackChanged(reverse: bool)

    // Most-recently-active bus names, newest first, so the popup can show the
    // players you actually used. Stored as names rather than player refs so an
    // entry for a closed player cannot dangle — orderByRecency just never
    // matches it.
    property var recentPlayerNames: []

    // Last observed isPlaying per bus. A bump only fires on a false -> true
    // transition, so a player that re-announces an unchanged playing state
    // cannot keep jumping to the front of the list.
    property var __wasPlaying: ({})

    property bool __reverse: false
    property var activeTrack: ({
        uniqueId: 0,
        artUrl: "",
        title: "Nothing playing",
        artist: "",
        album: ""
    })

    function isRealPlayer(player) {
        const name = player?.dbusName ?? "";
        return (
            // playerctld just mirrors other buses
            !name.startsWith("org.mpris.MediaPlayer2.playerctld")
            // non-instance mpd bus, duplicated by the instance one
            && !(name.endsWith(".mpd") && !name.endsWith("MediaPlayer2.mpd")));
    }

    function notePlaybackChange(player) {
        const name = player?.dbusName ?? "";
        if (!name)
            return;
        const was = root.__wasPlaying[name] === true;
        const now = player.isPlaying === true;
        root.__wasPlaying[name] = now;
        if (now && !was)
            root.bumpRecentPlayer(player);
    }

    function bumpRecentPlayer(player) {
        const name = player?.dbusName ?? "";
        if (!name || !root.isRealPlayer(player))
            return;
        root.recentPlayerNames = [name, ...root.recentPlayerNames.filter(n => n !== name)].slice(0, 16);
    }

    function orderByRecency(list) {
        const rank = name => {
            const i = root.recentPlayerNames.indexOf(name);
            return i === -1 ? root.recentPlayerNames.length : i;
        };
        return [...list].sort((a, b) => rank(a.dbusName) - rank(b.dbusName));
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: {
                root.notePlaybackChange(modelData);
                if (root.trackedPlayer == null || modelData.isPlaying) {
                    root.trackedPlayer = modelData;
                }
            }

            Component.onDestruction: {
                if (root.trackedPlayer == null || !root.trackedPlayer.isPlaying) {
                    for (const player of Mpris.players.values) {
                        if (player.isPlaying) {
                            root.trackedPlayer = player;
                            break;
                        }
                    }
                    if (root.trackedPlayer == null && Mpris.players.values.length != 0) {
                        root.trackedPlayer = Mpris.players.values[0];
                    }
                }
            }

            // Recency rides on the isPlaying PROPERTY change, not
            // playbackStateChanged: the state signal fires while isPlaying still
            // holds its old value, so a starting player reads as not-playing
            // there and never gets bumped.
            function onIsPlayingChanged() {
                root.notePlaybackChange(modelData);
            }

            function onPlaybackStateChanged() {
                if (root.trackedPlayer !== modelData)
                    root.trackedPlayer = modelData;
            }
        }
    }

    Connections {
        target: root.activePlayer
        ignoreUnknownSignals: true

        function onPostTrackChanged() {
            root.updateTrack();
        }

        function onTrackArtUrlChanged() {
            // Some players (cantata) send the cover update BEFORE the track
            // info, so an art change must not eat the reverse animation.
            if (root.activePlayer?.uniqueId === root.activeTrack.uniqueId && root.activePlayer?.trackArtUrl !== root.activeTrack.artUrl) {
                const r = root.__reverse;
                root.updateTrack();
                root.__reverse = r;
            }
        }
    }

    onActivePlayerChanged: root.updateTrack()

    function updateTrack() {
        root.activeTrack = {
            uniqueId: root.activePlayer?.uniqueId ?? 0,
            artUrl: root.activePlayer?.trackArtUrl ?? "",
            title: root.activePlayer?.trackTitle || "Unknown Title",
            artist: root.activePlayer?.trackArtist || "Unknown Artist",
            album: root.activePlayer?.trackAlbum || ""
        };
        root.trackChanged(root.__reverse);
        root.__reverse = false;
    }

    property bool isPlaying: root.activePlayer?.isPlaying ?? false
    property bool canTogglePlaying: root.activePlayer?.canTogglePlaying ?? false
    function togglePlaying() {
        if (root.canTogglePlaying)
            root.activePlayer.togglePlaying();
    }

    property bool canGoPrevious: root.activePlayer?.canGoPrevious ?? false
    function previous() {
        if (root.canGoPrevious) {
            root.__reverse = true;
            root.activePlayer.previous();
        }
    }

    property bool canGoNext: root.activePlayer?.canGoNext ?? false
    function next() {
        if (root.canGoNext) {
            root.__reverse = false;
            root.activePlayer.next();
        }
    }

    function setActivePlayer(player) {
        if (!player)
            return;
        root.bumpRecentPlayer(player);
        root.trackedPlayer = player;
    }

    // `qs ipc call mpris playPause` etc. Handy for binds that should work even
    // when the popup is closed.
    IpcHandler {
        target: "mpris"

        function playPause(): void {
            root.togglePlaying();
        }
        function previous(): void {
            root.previous();
        }
        function next(): void {
            root.next();
        }
        function pauseAll(): void {
            for (const player of Mpris.players.values) {
                if (player.canTogglePlaying && player.isPlaying)
                    player.togglePlaying();
            }
        }
    }
}
