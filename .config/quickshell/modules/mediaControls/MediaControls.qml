import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

/**
 * Now-playing popup: one card per MPRIS player, most recently played first.
 *
 * Opened by hovering the pill (MediaPill.qml), pinned by clicking it, and also
 * toggleable from Hyprland with `hl.dsp.global("quickshell:mediaToggle")`.
 * Transport without opening anything: `qs ipc call mpris playPause|next|previous`.
 *
 * Deliberately NOT using HyprlandFocusGrab: a grab steals the pointer, which
 * fights swaync's control center (also click-away dismissed) and would make a
 * hover-opened popup swallow clicks meant for the bar. Dismissal is hover-out
 * plus an explicit unpin instead.
 */
Scope {
    id: mediaScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            readonly property real barLeft: (root.screen.width - ConfigOptions.bar.waybarWidth) / 2
            readonly property var players: MprisController.orderByRecency(MprisController.players).slice(0, 4)

            screen: modelData
            visible: GlobalStates.mediaControlsOpen

            WlrLayershell.namespace: "quickshell:mediaControls"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors {
                top: true
                left: true
            }
            // Sits directly under the pill, left edges aligned.
            margins {
                top: ConfigOptions.bar.waybarMarginTop + ConfigOptions.bar.waybarHeight + 6
                left: root.barLeft + ConfigOptions.bar.waybarSidePadding
            }

            implicitWidth: ConfigOptions.media.popupWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: cardColumn.implicitHeight + Appearance.sizes.elevationMargin * 2

            mask: Region {
                item: GlobalStates.mediaControlsOpen ? cardColumn : null
            }

            HoverHandler {
                onHoveredChanged: GlobalStates.mediaHoverPopup = hovered
            }

            ColumnLayout {
                id: cardColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: Appearance.sizes.elevationMargin
                width: ConfigOptions.media.popupWidth
                spacing: Appearance.sizes.elevationMargin

                Repeater {
                    model: root.players

                    PlayerControl {
                        required property var modelData
                        player: modelData
                        Layout.fillWidth: true
                    }
                }

                // Something has to occupy the popup when nothing is playing, or
                // the mask collapses to zero height and hover-out never fires.
                Rectangle {
                    visible: root.players.length === 0
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1

                    StyledText {
                        anchors.centerIn: parent
                        text: "Nothing playing"
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }

    // Also reachable without a keybind: `qs ipc call media toggle`. Waybar
    // buttons and scripts can use this; `hyprctl dispatch global ...` is awkward
    // under the Lua config because hyprctl parses its argument as Lua.
    IpcHandler {
        target: "media"

        function toggle(): void {
            GlobalStates.mediaPinned = !GlobalStates.mediaControlsOpen;
            GlobalStates.mediaControlsOpen = GlobalStates.mediaPinned;
        }
        function open(): void {
            GlobalStates.mediaPinned = true;
            GlobalStates.mediaControlsOpen = true;
        }
        function close(): void {
            GlobalStates.mediaPinned = false;
            GlobalStates.mediaControlsOpen = false;
        }
    }

    GlobalShortcut {
        name: "mediaToggle"
        description: qsTr("Toggles the now playing popup")
        onPressed: {
            GlobalStates.mediaPinned = !GlobalStates.mediaControlsOpen;
            GlobalStates.mediaControlsOpen = GlobalStates.mediaPinned;
        }
    }

    GlobalShortcut {
        name: "mediaClose"
        description: qsTr("Closes the now playing popup")
        onPressed: {
            GlobalStates.mediaPinned = false;
            GlobalStates.mediaControlsOpen = false;
        }
    }
}
