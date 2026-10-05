pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "root:/modules/common"
import "root:/modules/bar"
import "root:/modules/bar/popouts"
import "root:/services"

/**
 * The notification centre, replacing swaync's control centre.
 *
 * Widget order and sizes come from .config/swaync/config.json:
 *   widgets: dnd, buttons-grid, mpris, title, notifications
 *   control-center-width 330, margin-top 5, margin-right 8
 *
 * The buttons-grid actions are the five from that file, with their exact
 * commands - power, lock, logout, airplane mode, mute.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData
        readonly property bool onThisScreen: Hyprland.focusedMonitor?.name === modelData.name

        screen: modelData
        color: "transparent"
        visible: NotifCentre.open && onThisScreen

        WlrLayershell.namespace: "quickshell:notification-centre"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        // swaync had positionX "center" / positionY "top", so the centre hung
        // from the top edge in the middle of the screen. Anchoring ONLY to top
        // leaves the compositor to centre the surface horizontally - adding
        // left or right here would pin it to that edge instead.
        anchors.top: true

        implicitWidth: Glass.centerWidth + 16
        // swaync control-center-height 900, clamped so it cannot run off a
        // shorter screen.
        implicitHeight: Math.min(900, (modelData?.height ?? 1080) - Glass.barHeight - Glass.barMarginTop - 24)
        exclusiveZone: 0

        HyprlandFocusGrab {
            windows: [win]
            active: win.visible
            onCleared: NotifCentre.open = false
        }

        Rectangle {
            id: panel

            width: Glass.centerWidth
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Glass.barHeight + Glass.barMarginTop + 5   // swaync control-center-margin-top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8

            color: Glass.panelSurface
            radius: Glass.panelRadius
            border.width: 1
            border.color: Glass.glassBorder

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 1
                height: 1
                color: Glass.glassHighlight
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Glass.panelPadding
                spacing: 10

                // ---- dnd ----
                RowLayout {
                    Layout.fillWidth: true

                    PopoutHeader {
                        text: "Do not disturb"
                    }

                    Rectangle {
                        implicitWidth: 38
                        implicitHeight: 20
                        radius: 10
                        color: Notifs.dnd ? Glass.accent : Glass.glassRaised
                        border.width: 1
                        border.color: Glass.glassBorder

                        Behavior on color {
                            CAnim {}
                        }

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            color: Glass.sel
                            y: 3
                            x: Notifs.dnd ? parent.width - width - 3 : 3

                            Behavior on x {
                                Anim { type: Anim.DefaultEffects }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.toggleDnd()
                        }
                    }
                }

                // ---- buttons-grid ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            {
                                g: 0xF0425,
                                t: "Power",
                                c: "scripts/Wlogout.sh"
                            },
                            {
                                g: 0xF033E,
                                t: "Lock",
                                c: "scripts/LockScreen.sh"
                            },
                            {
                                g: 0xF0343,
                                t: "Exit",
                                c: ""
                            },
                            {
                                g: 0xF001D,
                                t: "Airplane",
                                c: "scripts/AirplaneMode.sh"
                            },
                            {
                                g: 0xF075F,
                                t: "Mute",
                                c: "mute"
                            }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Glass.itemRadius
                            color: gridMa.containsMouse ? Glass.uiHover : Glass.glassRaised

                            Behavior on color {
                                CAnim {}
                            }

                            BarText {
                                anchors.centerIn: parent
                                text: String.fromCodePoint(modelData.g)
                                color: Glass.textGlass
                                shadowed: false
                            }

                            MouseArea {
                                id: gridMa

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const home = Quickshell.env("HOME");
                                    if (modelData.c === "")
                                        Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit");
                                    else if (modelData.c === "mute")
                                        Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]);
                                    else
                                        Quickshell.execDetached(["bash", `${home}/.config/hypr/${modelData.c}`]);
                                }
                            }
                        }
                    }
                }

                // ---- mpris ----
                Loader {
                    Layout.fillWidth: true
                    active: Players.hasPlayer
                    visible: active
                    sourceComponent: MediaPopout {
                        preferredWidth: Glass.centerWidth - 24
                    }
                }

                // ---- title ----
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2

                    PopoutHeader {
                        text: `Notifications${Notifs.count > 0 ? ` (${Notifs.count})` : ""}`
                    }

                    Rectangle {
                        implicitWidth: clearLabel.implicitWidth + 18
                        implicitHeight: 24
                        radius: Glass.itemRadius
                        color: clearMa.containsMouse ? Qt.rgba(1, 0.09, 0.27, 0.22) : Glass.glassRaised
                        visible: Notifs.hasAny

                        BarText {
                            id: clearLabel

                            anchors.centerIn: parent
                            text: " Clear"
                            color: clearMa.containsMouse ? Glass.maroon : Glass.textDim
                            pixelSize: Glass.fontMeta
                            shadowed: false
                        }

                        MouseArea {
                            id: clearMa

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.clearAll()
                        }
                    }
                }

                // ---- notifications ----
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: parent.parent.width
                        spacing: 8

                        Repeater {
                            model: Notifs.list

                            delegate: NotifCard {
                                required property var modelData

                                notif: modelData
                                Layout.fillWidth: true
                                onDismissed: Notifs.dismiss(modelData)
                            }
                        }

                        BarText {
                            visible: !Notifs.hasAny
                            text: "Nothing to see here"
                            color: Glass.textFaint
                            shadowed: false
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 24
                        }
                    }
                }
            }
        }
    }
}
