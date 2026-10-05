pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/**
 * Bar visibility, replacing `pkill -SIGUSR1 waybar`.
 *
 * Kept separate from PopoutState so the bar can be hidden without tearing down
 * the popout registry - the modules stay alive, they are just not drawn.
 */
Singleton {
    id: root

    property bool visible: true

    function toggle() {
        root.visible = !root.visible;
    }
}
