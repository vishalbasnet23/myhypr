import QtQuick
import Quickshell
import "root:/modules/common"
import "root:/services"
import ".."

/**
 * waybar custom/pacupdate:
 *   exec      $HOME/.config/hypr/UserScripts/PacmanUpdate.sh
 *   format    " 󰁈 "
 *   interval  21600
 *   on-click  PacmanUpdateTerminal.sh
 */
BarItem {
    id: root

    readonly property string home: Quickshell.env("HOME")

    WaybarScript {
        id: script

        command: ["bash", `${root.home}/.config/hypr/UserScripts/PacmanUpdate.sh`]
        intervalSec: 21600
        json: true
    }

    onClicked: Quickshell.execDetached(["bash", `${root.home}/.config/hypr/UserScripts/PacmanUpdateTerminal.sh`])

    BarText {
        text: " 󰁈 "
        color: script.valid && script.text !== "0" ? Glass.warn : Glass.textGlass
    }
}
