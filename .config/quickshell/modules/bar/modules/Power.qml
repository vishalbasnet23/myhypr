import QtQuick
import Quickshell
import "root:/modules/common"
import ".."

/**
 * waybar custom/power:
 *   left   Wlogout.sh
 *   right  ChangeBlur.sh
 */
BarItem {
    id: root

    readonly property string home: Quickshell.env("HOME")

    onClicked: button => Quickshell.execDetached(["bash", button === Qt.RightButton ? `${root.home}/.config/hypr/scripts/ChangeBlur.sh` : `${root.home}/.config/hypr/scripts/Wlogout.sh`])

    BarText {
        text: " ⏻ "
        // Glass.css #custom-power carries the red accent on hover
        color: root.containsMouse ? Glass.critical : Glass.textGlass
    }
}
