import QtQuick
import Quickshell
import "root:/modules/common"
import ".."

/**
 * waybar custom/cycle_wall:
 *   left   WallpaperSelect.sh
 *   right  WallpaperRandom.sh
 *   middle WaybarStyles.sh
 */
BarItem {
    id: root

    readonly property string home: Quickshell.env("HOME")

    onClicked: button => {
        if (button === Qt.RightButton)
            Quickshell.execDetached(["bash", `${root.home}/.config/hypr/UserScripts/WallpaperRandom.sh`]);
        else if (button === Qt.MiddleButton)
            Quickshell.execDetached(["bash", `${root.home}/.config/hypr/scripts/WaybarStyles.sh`]);
        else
            Quickshell.execDetached(["bash", `${root.home}/.config/hypr/UserScripts/WallpaperSelect.sh`]);
    }

    BarText {
        // custom/cycle_wall format: U+F03E (image) - the literal was empty
        text: `${String.fromCodePoint(0xF03E)} `
    }
}
