import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "root:/modules/common"
import ".."

/**
 * waybar hyprland/workspaces#pacman from ModulesWorkspaces:
 *
 *   format-icons: active  "<span font='12'>󰮯</span>"
 *                 empty   "<span font='8'></span>"
 *                 default "󰊠"
 *   persistent-workspaces: { "*": 5 }
 *   all-outputs: true, show-special: false
 *
 * Glass.css gives the active workspace the white @sel treatment and leaves
 * inactive ones at @wb-faint, which is what the colours below reproduce.
 */
BarItem {
    id: root

    required property var screen

    readonly property int persistent: 5
    readonly property var focused: Hyprland.focusedWorkspace
    // Bumped whenever the workspace list changes, to re-trigger `occupied`.
    property int tick: 0

    interactive: false

    // Quickshell populates Hyprland.workspaces lazily - without this the list
    // is empty on startup and every dot renders as "unoccupied". rawEvent
    // covers the cases the typed signals miss (workspace created/destroyed on
    // another monitor, special workspaces).
    Component.onCompleted: Hyprland.refreshWorkspaces()

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "workspace" || event.name === "createworkspace" || event.name === "destroyworkspace" || event.name === "openwindow" || event.name === "closewindow" || event.name === "movewindow")
                Hyprland.refreshWorkspaces();
            root.tick++;
        }
    }

    function occupied(id) {
        for (const ws of Hyprland.workspaces.values)
            if (ws.id === id)
                return (ws.toplevels?.values?.length ?? 0) > 0;
        return false;
    }

    onScrolled: delta => Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = "e${delta > 0 ? "-" : "+"}1" })` : `workspace e${delta > 0 ? "-" : "+"}1`)

    Repeater {
        model: root.persistent

        delegate: Rectangle {
            id: dot

            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: root.focused?.id === wsId
            readonly property bool used: root.tick, root.occupied(wsId)

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: label.implicitWidth + 8
            implicitHeight: label.implicitHeight + 2
            radius: Glass.itemRadius
            color: active ? Qt.rgba(1, 1, 1, 0.20) : ma.containsMouse ? Glass.uiHover : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Glass.animFast
                }
            }

            BarText {
                id: label

                anchors.centerIn: parent
                // The three format-icons from ModulesWorkspaces, by codepoint.
                // U+F0BAF and U+F02A0 are ASTRAL - above the BMP - so they are
                // built with fromCodePoint rather than pasted as literals,
                // which is where surrogate pairs get silently corrupted.
                // Sizes match the <span font='...'> wrappers waybar uses.
                text: dot.active ? String.fromCodePoint(0xF0BAF) : dot.used ? String.fromCodePoint(0xF02A0) : String.fromCodePoint(0xF111)
                pixelSize: dot.active ? 12 : dot.used ? Glass.fontSize : 8
                color: dot.active ? Glass.sel : dot.used ? Glass.textGlass : Glass.textFaint
            }

            MouseArea {
                id: ma

                anchors.fill: parent
                hoverEnabled: true
                onClicked: Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.workspace(${dot.wsId})` : `workspace ${dot.wsId}`)
            }
        }
    }
}
