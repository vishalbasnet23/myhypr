pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "root:/modules/common"

/**
 * One full-screen, click-through overlay per screen. Panels live inside it as
 * anchored Items.
 *
 * Two things make "full screen" acceptable rather than a desktop-eating
 * rectangle:
 *
 *   exclusiveZone: 0  - it reserves no space, so windows lay out as if it were
 *                       not there. The bar keeps its own separate exclusive
 *                       strip.
 *   mask: Region      - input only lands on the panels that are actually open.
 *                       Without this the overlay would swallow every click on
 *                       the desktop. The region is rebuilt from whichever
 *                       panels are on screen.
 *
 * Namespace is "quickshell:panels" so the blur layer rule in
 * UserConfigs/WindowRules.lua applies to it. That rule lives in the Lua config
 * rather than being applied with `hyprctl eval`, so it survives a reload.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData
        readonly property string screenName: modelData.name
        // Panels only ever open on the focused screen.
        readonly property bool focused: Hyprland.focusedMonitor?.name === screenName

        screen: modelData
        color: "transparent"

        WlrLayershell.namespace: "quickshell:panels"
        WlrLayershell.layer: WlrLayer.Overlay
        // Exclusive ONLY while a panel actually needs typing (launcher search,
        // session menu). Holding focus the rest of the time steals keys from
        // the focused window for no reason - vast-shell gates it the same way.
        readonly property bool needsKeyboard: false   // set by panels that type
        WlrLayershell.keyboardFocus: needsKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        readonly property bool anyOpen: {
            ShellState.revision;      // dependency: openOn is a plain object
            return ShellState.anyOpen(screenName);
        }

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        exclusionMode: ExclusionMode.Ignore
        visible: anyOpen


        // Explicit geometry bindings, NOT `item:` and NOT derived from
        // contentItem.children.
        //
        // Two ways this has already failed silently:
        //   * `Region { item: dashboard }` captured first-frame geometry
        //     (verticalCenter against a zero-height parent put it at y=-230)
        //     and stayed pinned off-screen.
        //   * Deriving it from `contentItem.children` via Variants - the
        //     vast-shell pattern - produced an EMPTY mask here, because
        //     `children` does not notify, so the model snapshots before the
        //     panel is constructed and never re-evaluates.
        //
        // An undersized mask swallows every click with no warning, so this
        // stays explicit. Each new panel adds a Region here, deliberately.
        mask: Region {
            x: dashboard.x
            y: dashboard.y
            width: dashboard.width
            height: dashboard.height
        }

        // The grab must NOT go active in the same frame the panel opens. When a
        // panel is opened from a keybind, focus is still on another window, so
        // an immediately-active grab fires `cleared` at once and closes the
        // panel before it finishes animating in. The same delay exists in this
        // config's overview (ConfigOptions.hacks.arbitraryRaceConditionDelay).
        Timer {
            id: grabDelay

            interval: 60
            onTriggered: grab.active = win.anyOpen
        }

        onAnyOpenChanged: {
            if (anyOpen)
                grabDelay.restart();
            else {
                grabDelay.stop();
                grab.active = false;
            }
        }

        HyprlandFocusGrab {
            id: grab

            windows: [win]
            active: false
            onCleared: ShellState.closeAll()
        }

        // ---- panels ----
        Dashboard {
            id: dashboard

            screenName: win.screenName
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Glass.panelEdgeGap
        }
    }
}
