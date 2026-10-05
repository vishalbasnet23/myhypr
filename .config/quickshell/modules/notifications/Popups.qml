pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "root:/modules/common"
import "root:/services"

/**
 * Floating notification popups.
 *
 * swaync config.json placed these at positionX "center", positionY "top",
 * 350px wide, so they land under the bar in the middle of the screen. Only the
 * focused monitor shows them, which is what swaync did by default.
 *
 * The layer is "quickshell:notifications" so WindowRules.lua can blur it the
 * same way it blurred swaync-notification-window.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        // Track the popups belonging to this screen.
        property var shown: []

        screen: modelData
        color: "transparent"
        visible: stack.children.length > 0

        WlrLayershell.namespace: "quickshell:notifications"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors.top: true
        anchors.left: true
        anchors.right: true

        implicitHeight: Math.max(1, stack.implicitHeight + Glass.barHeight + Glass.barMarginTop + 12)
        // Popups must not push windows around.
        exclusiveZone: 0
        mask: Region {
            item: stack
        }

        Column {
            id: stack

            width: Glass.popupWidth
            anchors.horizontalCenter: parent.horizontalCenter
            y: Glass.barHeight + Glass.barMarginTop + 8
            spacing: 8
        }

        Component {
            id: cardComponent

            NotifCard {
                id: card

                width: stack.width
                popup: true

                // Slide down and fade in.
                opacity: 0
                transform: Translate {
                    id: slide

                    y: -12
                }

                Component.onCompleted: {
                    opacity = 1;
                    slide.y = 0;
                }

                Behavior on opacity {
                    Anim { type: Anim.DefaultEffects }
                }

                Timer {
                    id: life

                    interval: Notifs.timeoutFor(card.notif)
                    running: interval > 0 && !cardHover.hovered
                    onTriggered: card.dismissed()
                }

                // Hovering pauses the countdown, so a notification cannot
                // vanish while it is being read.
                HoverHandler {
                    id: cardHover
                }

                onDismissed: {
                    Notifs.dismiss(card.notif);
                    card.destroy();
                }
            }
        }

        Connections {
            target: Notifs

            function onPopup(n) {
                // Only the focused monitor shows popups, matching swaync.
                if (Hyprland.focusedMonitor?.name !== win.modelData.name)
                    return;
                cardComponent.createObject(stack, {
                    notif: n
                });
            }
        }
    }
}
