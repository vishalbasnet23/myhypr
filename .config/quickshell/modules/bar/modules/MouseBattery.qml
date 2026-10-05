import QtQuick
import Quickshell
import "root:/modules/common"
import "root:/services"
import ".."

/**
 * waybar custom/mousebattery (from UserModules):
 *   exec            $HOME/.config/hypr/UserScripts/MouseBattery.sh
 *   interval        60
 *   hide-empty-text true
 *
 * `hide-empty-text` is why this collapses entirely when no wireless mouse is
 * connected, rather than leaving a gap in the drawer.
 */
BarItem {
    id: root

    visible: script.valid && script.text.trim().length > 0

    WaybarScript {
        id: script

        command: ["bash", `${Quickshell.env("HOME")}/.config/hypr/UserScripts/MouseBattery.sh`]
        intervalSec: 60
        json: true
    }

    BarText {
        text: script.text
    }
}
