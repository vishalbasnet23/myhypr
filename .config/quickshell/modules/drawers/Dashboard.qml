pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/modules/common"
import "root:/modules/bar"
import "root:/modules/drawers/dashboard"

/**
 * Left-edge dashboard drawer: Dashboard / Media / Performance / Weather.
 *
 * The wrapper slides; the background never fades (see PanelWrapper for why).
 * Pages slide horizontally under a moving indicator, and the content Loader is
 * only active while the panel is on screen, so a closed dashboard costs
 * nothing but the wrapper Item.
 */
PanelWrapper {
    id: root

    required property string screenName

    readonly property int tabIndex: tabBar.current
    readonly property int panelWidth: Glass.dashboardWidth
    // Reference sizes: 400x470, centred vertically on the left edge.
    readonly property int panelHeight: 470

    edge: "left"
    shouldBeActive: {
        ShellState.revision;
        return ShellState.isOpen("dashboard", screenName);
    }

    implicitWidth: panelWidth
    implicitHeight: panelHeight

    GlassPanel {
        anchors.fill: parent

        // Content fades; the surface behind it does not.
        Item {
            anchors.fill: parent
            opacity: 1 - root.offsetScale

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Glass.panelPadding
                spacing: Glass.cardGap

                DashTabs {
                    id: tabBar

                    Layout.fillWidth: true
                }

                Loader {
                    id: pages

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    // Cheap when closed, per the brief.
                    active: root.shouldBeActive || root.onScreen

                    sourceComponent: Item {
                        clip: true

                        Row {
                            id: strip

                            width: parent.width * 4
                            height: parent.height
                            x: -root.tabIndex * parent.width

                            Behavior on x {
                                Anim {
                                    type: Anim.Emphasized
                                }
                            }

                            DashHome {
                                width: pages.width
                                height: pages.height
                            }

                            DashMedia {
                                width: pages.width
                                height: pages.height
                            }

                            DashPerf {
                                width: pages.width
                                height: pages.height
                            }

                            DashWeather {
                                width: pages.width
                                height: pages.height
                            }
                        }
                    }
                }
            }
        }
    }
}
