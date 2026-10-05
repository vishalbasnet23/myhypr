pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    // "top" (bar at top, dashboard on the left) or "left" (upstream default:
    // bar on the left, dashboard dropping from the top). Swapping position is
    // a file-profile swap + shell restart, not a live property, so it's read
    // from a marker file the switch script writes rather than Config.
    readonly property list<MenuItem> positionItems: [
        MenuItem {
            text: Tr.trCtx("Top", "bar position")
            icon: "dock_to_bottom"
        },
        MenuItem {
            text: Tr.trCtx("Left", "bar position")
            icon: "dock_to_right"
        }
    ]
    readonly property var positionValues: ["top", "left"]
    property string currentPosition: "top"

    title: Tr.tr("Taskbar")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        FileView {
            id: positionFile

            path: Quickshell.shellPath("profiles/current")
            onLoaded: root.currentPosition = text().trim()
        }

        // Position
        SectionHeader {
            first: true
            text: Tr.tr("Position")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("Bar position")
            subtext: Tr.tr("Restarts the shell to apply - a handful of seconds of a blank screen is normal")
            menuItems: root.positionItems
            active: root.positionItems[Math.max(0, root.positionValues.indexOf(root.currentPosition))]
            onSelected: item => {
                const value = root.positionValues[root.positionItems.indexOf(item)];
                Quickshell.execDetached(["bash", Quickshell.shellPath("profiles/switch.sh"), value]);
            }
        }

        // Behaviour
        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Persistent")
            subtext: Tr.tr("Keep the bar visible at all times")
            checked: Config.bar.persistent
            onToggled: GlobalConfig.bar.persistent = checked
        }

        ToggleRow {
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Reveal the bar when the cursor reaches the screen edge")
            checked: Config.bar.showOnHover
            onToggled: GlobalConfig.bar.showOnHover = checked
        }

        StepperRow {
            last: true
            label: Tr.tr("Drag threshold")
            subtext: Tr.tr("Pixels dragged before the bar reveals")
            value: Config.bar.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.bar.dragThreshold = v
        }

        // Components
        SectionHeader {
            text: Tr.tr("Components")
        }

        NavRow {
            first: true
            icon: "workspaces"
            text: Tr.tr("Workspaces")
            subtext: Tr.tr("Indicators, window icons")
            onClicked: root.nState.openSubPage(6)
        }

        NavRow {
            icon: "web_asset"
            text: Tr.tr("Active window")
            subtext: Tr.tr("Title display, popout")
            onClicked: root.nState.openSubPage(7)
        }

        NavRow {
            icon: "widgets"
            text: Tr.tr("Tray")
            subtext: Tr.tr("System tray icons")
            onClicked: root.nState.openSubPage(8)
        }

        NavRow {
            icon: "signal_cellular_alt"
            text: Tr.tr("Status icons")
            subtext: Tr.tr("Visible indicators")
            onClicked: root.nState.openSubPage(9)
        }

        NavRow {
            last: true
            icon: "schedule"
            text: Tr.tr("Clock")
            subtext: Tr.tr("Date, icon, background")
            onClicked: root.nState.openSubPage(10)
        }

        // Scroll actions
        SectionHeader {
            text: Tr.tr("Scroll actions")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Workspaces")
            subtext: Tr.tr("Scroll over the workspace indicator to switch workspaces")
            checked: Config.bar.scrollActions.workspaces
            onToggled: GlobalConfig.bar.scrollActions.workspaces = checked
        }

        ToggleRow {
            text: Tr.tr("Volume")
            subtext: Tr.tr("Scroll on the top half of the bar to adjust volume")
            checked: Config.bar.scrollActions.volume
            onToggled: GlobalConfig.bar.scrollActions.volume = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Brightness")
            subtext: Tr.tr("Scroll on the bottom half of the bar to adjust brightness")
            checked: Config.bar.scrollActions.brightness
            onToggled: GlobalConfig.bar.scrollActions.brightness = checked
        }
    }
}
