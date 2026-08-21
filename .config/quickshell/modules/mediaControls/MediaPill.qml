import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

/**
 * The bar indicator, as a layer-shell surface of its own.
 *
 * This replaces waybar's `mpris` module: waybar now carries a fixed-width
 * `custom/mediapill` spacer in its place and this window is parked over it.
 * Owning the surface is what makes hover possible at all — waybar exposes no
 * hover event you can bind a command to, only click and scroll.
 *
 * Placement is computed, not guessed: waybar is centred with a fixed width, so
 * its left edge is (screen.width - waybarWidth) / 2 and the pill sits one
 * modules-left margin+padding further in. Every number lives in
 * ConfigOptions.bar so a waybar layout change is a one-line edit here.
 * The spacer is FIRST in modules-left on purpose — anything before it (tray
 * icons, workspace pills) changes width at runtime and would drag the
 * alignment with it.
 */
Scope {
    id: pillScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData

            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            readonly property real barLeft: (root.screen.width - ConfigOptions.bar.waybarWidth) / 2

            // Overlay, because waybar is on `top` and same-layer ordering is
            // creation-ordered — on `top` the pill would end up under the bar
            // whenever waybar restarts last. The cost of Overlay is that it
            // also floats above fullscreen windows, so hide it there.
            readonly property bool monitorHasFullscreen: {
                const windows = HyprlandData.windowList ?? [];
                const activeWs = root.monitor?.activeWorkspace?.id ?? -1;
                return windows.some(w => w.workspace?.id === activeWs && w.fullscreen > 0);
            }

            screen: modelData
            visible: !root.monitorHasFullscreen

            WlrLayershell.namespace: "quickshell:mediaPill"
            WlrLayershell.layer: WlrLayer.Overlay
            // Waybar already reserves the strip; reserving it twice would push
            // every window down by another bar height. Ignore mode is also
            // required — with Normal, waybar's own exclusive zone offsets this
            // surface and the pill lands 41px BELOW the bar instead of in it.
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors {
                top: true
                left: true
            }
            margins {
                top: ConfigOptions.bar.waybarMarginTop
                left: root.barLeft + ConfigOptions.bar.waybarSidePadding
            }

            implicitWidth: ConfigOptions.media.pillWidth
            implicitHeight: ConfigOptions.bar.waybarHeight

            mask: Region {
                item: pill
            }

            Item {
                id: pill
                anchors.fill: parent

                HoverHandler {
                    id: pillHover
                    onHoveredChanged: {
                        if (hovered) {
                            GlobalStates.mediaHoverSource = true;
                            GlobalStates.mediaControlsOpen = true;
                        } else {
                            GlobalStates.mediaHoverSource = false;
                            closeTimer.restart();
                        }
                    }
                }

                // Grace period so the pointer can travel from pill to popup
                // without the popup vanishing underneath it.
                Timer {
                    id: closeTimer
                    interval: ConfigOptions.media.hoverCloseDelay
                    onTriggered: {
                        if (!GlobalStates.mediaHoverSource && !GlobalStates.mediaHoverPopup && !GlobalStates.mediaPinned)
                            GlobalStates.mediaControlsOpen = false;
                    }
                }

                Connections {
                    target: GlobalStates
                    function onMediaHoverPopupChanged() {
                        if (!GlobalStates.mediaHoverPopup)
                            closeTimer.restart();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: event => {
                        if (event.button === Qt.MiddleButton) {
                            MprisController.togglePlaying();
                            return;
                        }
                        // Left click pins the popup open, so it survives the
                        // pointer leaving. Click again to unpin and close.
                        GlobalStates.mediaPinned = !GlobalStates.mediaPinned;
                        GlobalStates.mediaControlsOpen = GlobalStates.mediaPinned || pillHover.hovered;
                    }
                    onWheel: event => {
                        if (event.angleDelta.y > 0)
                            MprisController.previous();
                        else
                            MprisController.next();
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 1
                    anchors.bottomMargin: 1
                    radius: Appearance.rounding.full
                    color: pillHover.hovered ? Appearance.colors.colLayer1Hover : "transparent"

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        StyledText {
                            // nf-fa-music / nf-fa-play, from a Nerd Font: the
                            // configured iconFont is "FiraConde Nerd Font", a
                            // typo that resolves to Noto Sans, and Material
                            // Symbols is not installed.
                            text: MprisController.isPlaying ? "" : ""
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: Appearance.font.pixelSize.textBase
                            color: MprisController.isPlaying ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: MprisController.activePlayer ? `${MprisController.activeTrack.title} · ${MprisController.activeTrack.artist}` : "Nothing playing"
                            font.pixelSize: Appearance.font.pixelSize.textSmall
                            color: Appearance.m3colors.m3primaryText
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                }
            }
        }
    }
}
