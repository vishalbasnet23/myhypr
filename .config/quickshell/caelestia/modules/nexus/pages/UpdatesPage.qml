pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    // paru first, falling back to yay then plain pacman - matches the AUR
    // helpers actually installed on this machine (see
    // .config/hypr/scripts/Distro_update.sh for the same preference order).
    readonly property string updateCommand: "if command -v paru >/dev/null 2>&1; then paru -Syu; elif command -v yay >/dev/null 2>&1; then yay -Syu; else sudo pacman -Syu; fi; echo; read -n1 -s -r -p 'Press any key to close...'"

    // Repo updates (checkupdates, no sync/root needed) + AUR updates via
    // whichever helper is installed. Mirrors PacmanUpdate.sh's checkupdates
    // use but also counts AUR since the button itself runs paru/yay, not
    // plain pacman.
    readonly property string countCommand: "{ checkupdates 2>/dev/null; command -v paru >/dev/null 2>&1 && paru -Qua 2>/dev/null || (command -v yay >/dev/null 2>&1 && yay -Qua 2>/dev/null); } | wc -l"

    property int updateCount: -1 // -1 = checking

    function refreshUpdateCount(): void {
        updateCount = -1;
        countProc.running = true;
    }

    title: Tr.tr("Updates")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Process {
            id: countProc

            running: true
            command: ["bash", "-c", root.countCommand]
            stdout: StdioCollector {
                onStreamFinished: root.updateCount = parseInt(text.trim()) || 0
            }
        }

        Process {
            id: updateProc

            command: ["alacritty", "-e", "bash", "-c", root.updateCommand]
            onExited: root.refreshUpdateCount()
        }

        SectionHeader {
            first: true
            text: Tr.tr("System updates")
        }

        InfoRow {
            first: true
            icon: "inventory_2"
            label: Tr.tr("Status")
            value: {
                if (root.updateCount < 0)
                    return Tr.tr("Checking…");
                if (root.updateCount === 0)
                    return Tr.tr("Up to date");
                return Tr.trCtx("%1 update(s) available", "updates page status").arg(root.updateCount);
            }
        }

        RowButton {
            icon: "update"
            text: Tr.tr("Update system")
            subtext: Tr.tr("Opens a terminal and runs the Arch update command")
            trailingIcon: "open_in_new"
            onClicked: updateProc.running = true
        }

        RowButton {
            last: true
            icon: "refresh"
            text: Tr.tr("Check again")
            onClicked: root.refreshUpdateCount()
        }
    }
}
