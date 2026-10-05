import QtQuick
import Quickshell
import "root:/modules/common"
import "root:/modules/notifications"
import "root:/services"
import ".."

/**
 * waybar custom/swaync:
 *   format     "{} {icon} "
 *   on-click   swaync-client -t -sw     (toggle control centre)
 *   on-click-right swaync-client -d -sw (toggle DND)
 *
 * Reads services/Notifs.qml - the shell's own NotificationServer - rather
 * than shelling out to swaync-client. swaync is retired.
 */
BarItem {
    id: root

    onClicked: button => button === Qt.RightButton ? Notifs.toggleDnd() : NotifCentre.toggle()

    BarText {
        text: {
            // format-icons from ModulesCustom, by codepoint:
            //   U+F0A2 bell, U+F1F7 bell-off (dnd), U+F444 unread dot
            const n = Notifs.count;
            const bell = String.fromCodePoint(Notifs.dnd ? 0xF1F7 : 0xF0A2);
            const dot = n > 0 ? String.fromCodePoint(0xF444) : "";
            return `${n > 0 ? n : ""} ${bell}${dot} `;
        }
        // waybar marks the unread state with a red superscript dot
        color: Notifs.count > 0 ? Glass.critical : Glass.textGlass
    }
}
