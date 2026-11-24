pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

StyledClippingRect {
    id: root

    required property ShellScreen screen
    required property bool fullscreen

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool onSpecial: monitor?.lastIpcObject.specialWorkspace?.name !== ""
    readonly property int activeWsId: monitor.activeWorkspace?.id ?? 1
    readonly property int activeWsIdx: workspaceIndex(activeWsId)
    readonly property int shown: Math.max(1, Config.bar.workspaces.shown)

    readonly property var wsIds: {
        if (Config.bar.workspaces.showUnoccupied)
            return Array.from({
                length: shown
            }, (_, i) => i + 1);

        const allMonitors = !Config.bar.workspaces.perMonitor;
        const ignoredTags = GlobalConfig.bar.workspaces.ignoredTags;
        const workspaces = Hypr.workspaces.values.filter(w => w.id > 0 && (allMonitors || w.monitor === root.monitor) && (w.id === activeWsId || w.toplevels.values.some(t => !Hypr.isToplevelIgnored(t, ignoredTags))));
        const currentIdx = workspaces.findIndex(w => w.id === activeWsId);
        if (currentIdx < 0)
            return [];

        const end = CUtils.clamp(currentIdx + 1, Math.min(shown, workspaces.length), workspaces.length);
        const start = Math.max(0, end - shown);

        return workspaces.slice(start, end).map(w => w.id);
    }

    // Only relevant for when showUnoccupied is true
    readonly property int groupOffset: {
        if (!Config.bar.workspaces.showUnoccupied)
            return 0;
        return Math.floor((activeWsId - 1) / shown) * shown;
    }

    property real blur: onSpecial ? 1 : 0

    function workspaceIndex(id: int): int {
        if (!Config.bar.workspaces.showUnoccupied)
            return wsIds.indexOf(id);

        let index = id - 1;
        while (index < 0)
            index += shown;
        return index % shown;
    }

    // -- row-level focus overlays (underline / ring / trail), gated by
    // WorkspaceExtra.style. Positioned by reading the active delegate's
    // real geometry from the Row - plain Items have real x/width here
    // (unlike the LazyListView-driven vertical bar), so no attached
    // geometry component is needed.
    Component {
        id: underlineOverlay

        Item {
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.7
                height: 2
                radius: 1
                color: Colours.palette.m3primary
            }
        }
    }

    Component {
        id: ringOverlay

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.full
            color: "transparent"
            border.width: 2
            border.color: Colours.palette.m3primary
        }
    }

    Component {
        id: trailOverlay

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.full
            color: Colours.palette.m3primary
            opacity: Colours.light ? 0.6 : 0.35

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.4
                blurMax: 24
            }
        }
    }

    implicitHeight: Tokens.sizes.bar.innerWidth
    implicitWidth: workspaces.width + Tokens.padding.extraSmall * 2

    color: Colours.tPalette.m3surfaceContainer
    radius: Config.appearance.rounding.scale > 0 ? Tokens.rounding.full : 0

    Item {
        anchors.fill: parent
        scale: root.onSpecial ? 0.8 : 1
        opacity: root.onSpecial ? 0.5 : 1
        visible: !root.fullscreen

        layer.enabled: root.blur > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blur
            blurMax: 32
        }

        // NOTE: occupied-bg / gap-marker / sliding active-indicator overlays are
        // disabled here - they're built on LazyListView's vertical-only attached
        // geometry (layoutY, visibleHeight) with no horizontal equivalent in the
        // C++ component, so porting them is out of scope for the top-bar move.
        Row {
            id: workspaces

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.extraSmall

            spacing: Tokens.spacing.extraSmall

            Repeater {
                id: repeater

                model: ScriptModel {
                    values: root.wsIds
                }

                delegate: Workspace {
                    activeWsId: root.activeWsId
                    ws: Config.bar.workspaces.showUnoccupied ? root.groupOffset + index + 1 : modelData
                    monitor: root.monitor

                    displayType: Config.bar.workspaces.displayType
                    showWindows: Config.bar.workspaces.showWindows
                    iconRules: GlobalConfig.bar.workspaces.workspaceIcons
                    activeLabel: Config.bar.workspaces.activeLabel
                    occupiedLabel: Config.bar.workspaces.occupiedLabel
                    label: Config.bar.workspaces.label
                }
            }
        }

        MouseArea {
            anchors.fill: workspaces
            onClicked: event => {
                const ws = (workspaces.childAt(event.x, event.y) as Workspace)?.ws;
                if (!ws)
                    return;
                if (Hypr.activeWsId !== ws)
                    Hypr.focusWorkspace(ws);
                else
                    Hypr.toggleSpecial("special");
            }
        }

        Loader {
            id: focusOverlay

            // repeater.itemAt() isn't itself a tracked binding dependency, so a
            // plain `readonly property: repeater.itemAt(...)` binding only
            // re-evaluates when activeWsIdx changes - it stays stuck at
            // whatever it first resolved to (often null, before the Repeater
            // has finished instantiating) if the user switches style without
            // switching workspace. Refresh imperatively on every signal that
            // could change which item is "active" instead.
            property Item activeItem: null

            function refresh(): void {
                activeItem = repeater.itemAt(root.activeWsIdx) ?? null;
            }

            Component.onCompleted: refresh()

            Connections {
                function onActiveWsIdxChanged(): void {
                    focusOverlay.refresh();
                }

                target: root
            }

            Connections {
                function onCountChanged(): void {
                    focusOverlay.refresh();
                }
                function onItemAdded(): void {
                    focusOverlay.refresh();
                }
                function onItemRemoved(): void {
                    focusOverlay.refresh();
                }

                target: repeater
            }

            active: !!activeItem && ["underline", "ring", "trail"].includes(WorkspaceExtra.style)
            z: -1

            x: activeItem ? workspaces.x + activeItem.x : 0
            y: activeItem ? workspaces.y + activeItem.y : 0
            width: activeItem ? activeItem.width : 0
            height: activeItem ? activeItem.height : 0

            sourceComponent: {
                if (WorkspaceExtra.style === "underline")
                    return underlineOverlay;
                if (WorkspaceExtra.style === "ring")
                    return ringOverlay;
                if (WorkspaceExtra.style === "trail")
                    return trailOverlay;
                return null;
            }

            Behavior on x {
                Anim {
                    type: WorkspaceExtra.style === "trail" ? Anim.SlowSpatial : Anim.DefaultSpatial
                }
            }

            Behavior on width {
                Anim {
                    type: WorkspaceExtra.style === "trail" ? Anim.SlowSpatial : Anim.DefaultSpatial
                }
            }
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: specialWs

        anchors.fill: parent

        asynchronous: true
        active: opacity > 0
        opacity: root.onSpecial ? 1 : 0

        sourceComponent: Item {
            StyledRect {
                anchors.fill: parent
                radius: Config.appearance.rounding.scale > 0 ? Tokens.rounding.full : 0
                color: Qt.alpha(Colours.palette.m3scrim, Colours.light ? 0 : 0.2)
            }

            SpecialWorkspaces {
                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall
                monitor: root.monitor

                scale: 0.5
                Component.onCompleted: scale = Qt.binding(() => root.onSpecial ? 1 : 0.5)

                Behavior on scale {
                    Anim {}
                }
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Behavior on blur {
        Anim {
            type: Anim.StandardSmall
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
