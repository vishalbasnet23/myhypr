pragma ComponentBehavior: Bound

import "modules"
import "popouts"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/modules/common"

/**
 * The Vibrant Glass bar - a port of waybar's configs/VB23 profile.
 *
 * Geometry is taken from that file: a 1444px-wide floating bar, centred, 5px
 * below the top edge, 4px between modules. The three pills correspond to
 * modules-left / modules-center / modules-right, and the module ORDER below is
 * the order in those arrays.
 *
 * COMPARISON MODE: while waybar is still running this sits one bar-height
 * lower (Glass.barCompareOffset) so the two can be judged side by side. Set
 * that token to 0 to take the top slot.
 *
 * The layer is named "quickshell:bar" so WindowRules.lua can blur it exactly
 * as it blurs waybar. Without a matching layerrule the glass reads flat: the
 * pill fill is only 13% opaque and depends entirely on what is behind it.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property var modelData

        screen: modelData
        color: "transparent"
        visible: BarState.visible

        WlrLayershell.namespace: "quickshell:bar"
        WlrLayershell.layer: WlrLayer.Top

        anchors.top: true
        anchors.left: true
        anchors.right: true

        implicitHeight: Glass.barHeight + Glass.barMarginTop + Glass.barCompareOffset
        exclusiveZone: BarState.visible ? Glass.barHeight + Glass.barMarginTop + Glass.barCompareOffset : 0

        Item {
            id: barBody

            width: Math.min(Glass.barWidth, root.width)
            height: Glass.barHeight
            anchors.horizontalCenter: parent.horizontalCenter
            y: Glass.barMarginTop + Glass.barCompareOffset

            // ---- modules-left ----
            // hyprland/workspaces#pacman, custom/separator#dot-line, network#speed-alt
            Pill {
                anchors.left: parent.left
                anchors.leftMargin: Glass.pillMarginH
                anchors.verticalCenter: parent.verticalCenter

                Workspaces {
                    screen: root.modelData
                }

                Separator {
                    kind: "dot-line"
                }

                NetworkSpeed {}
            }

            // ---- modules-center ----
            // custom/weather, group/time, group/notify
            Pill {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                Weather {}

                // group/time -> the clock owns a calendar popout, which also
                // carries the Kathmandu clock the drawer used to reveal.
                Clock {
                    popoutId: "time"
                    popout: Component {
                        TimePopout {}
                    }
                }

                // Now playing. No waybar counterpart - VB23 never placed the
                // mpris module - so it follows the bar's own conventions.
                Media {
                    popout: Component {
                        MediaPopout {}
                    }
                }

                // group/notify -> swaync badge owns an actions popout holding
                // what pacupdate and cycle_wall used to be.
                SwayncBadge {
                    popoutId: "notify"
                    popout: Component {
                        NotifyPopout {}
                    }
                }
            }

            // ---- modules-right ----
            // battery, backlight, group/audio, group/mobo_drawer, tray, custom/power
            Pill {
                anchors.right: parent.right
                anchors.rightMargin: Glass.pillMarginH
                anchors.verticalCenter: parent.verticalCenter

                Battery {}

                Separator {
                    kind: "blank"
                }

                Backlight {}

                Separator {
                    kind: "blank"
                }

                // group/audio -> sink stays in the bar, both sliders and the
                // device names move into the popout.
                Audio {
                    popoutId: "audio"
                    popout: Component {
                        AudioPopout {}
                    }
                }

                Separator {
                    kind: "blank"
                }

                // group/mobo_drawer -> temperature stays in the bar; cpu,
                // memory, disk and temp get meters in the popout.
                MoboStats {
                    kind: "temperature"
                    popoutId: "mobo"
                    popout: Component {
                        MoboPopout {}
                    }
                }

                MouseBattery {}

                Tray {}

                Power {}
            }
        }

        // One popout window per screen; PopoutState decides which module owns
        // it and which screen shows it.
        Popout {
            barWindow: root
        }
    }
}
