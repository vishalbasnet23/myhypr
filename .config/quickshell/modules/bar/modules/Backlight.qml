import QtQuick
import "root:/modules/common"
import "root:/services"
import ".."

/**
 * waybar backlight: icon only, scroll to change.
 * The scroll handlers in Modules call scripts/Brightness.sh, which needs
 * brightnessctl - see services/Backlight.qml for why that matters.
 */
BarItem {
    id: root

    onScrolled: delta => Backlight.step(delta > 0 ? 10 : -10)

    BarText {
        text: Backlight.icon
        color: Backlight.writable ? Glass.textGlass : Glass.textDim
    }
}
