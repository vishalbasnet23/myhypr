import QtQuick
import "root:/modules/common"
import "root:/services"
import ".."

/**
 * Compact now-playing module. waybar had an `mpris` module defined but VB23
 * never placed it, so this has no upstream counterpart to match - it follows
 * the bar's own conventions instead.
 *
 * Collapses to nothing when no player is present, the same way
 * custom/mousebattery does with hide-empty-text.
 *
 * Left click toggles playback, scroll skips tracks, and the whole thing owns
 * the media popout.
 */
BarItem {
    id: root

    visible: Players.hasPlayer
    popoutId: "media"

    onClicked: button => {
        if (button === Qt.MiddleButton)
            Players.next();
        else
            Players.toggle();
    }

    onScrolled: delta => delta > 0 ? Players.previous() : Players.next()

    // Icon only. A track title in the bar re-flows the centre pill on every
    // song change and runs to arbitrary length; the detail lives in the
    // popout instead.
    //   U+F001 music note, U+F04B play, U+F04C pause
    BarText {
        text: String.fromCodePoint(0xF001)
        // State is carried by colour: accent while playing, dim when paused.
        color: Players.playing ? Glass.accent : Glass.textDim

        Behavior on color {
            ColorAnimation {
                duration: Glass.animFast
            }
        }
    }
}
