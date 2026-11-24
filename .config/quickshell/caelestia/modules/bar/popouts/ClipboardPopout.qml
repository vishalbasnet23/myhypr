pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

// Hover popout for the clipboard status icon: recent history at a glance,
// click an entry to paste it, footer button opens the full picker.

Item {
    id: root

    required property PopoutState popouts

    property bool clearArmed: false

    implicitWidth: Tokens.sizes.bar.trayMenuWidth
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.bottomMargin: Tokens.spacing.extraSmall
            text: Tr.tr("Clipboard")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        StyledText {
            visible: Clipboard.count === 0
            text: Tr.tr("Nothing copied yet")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }

        Repeater {
            model: ScriptModel {
                values: Clipboard.displayRows("", 8)
            }

            delegate: Item {
                id: row

                required property var modelData

                implicitWidth: layout.width
                implicitHeight: rowText.implicitHeight + Tokens.padding.small * 2

                StateLayer {
                    id: rowState

                    radius: Tokens.rounding.medium
                    onClicked: {
                        Clipboard.paste(row.modelData);
                        root.popouts.hasCurrent = false;
                    }
                }

                MaterialIcon {
                    id: rowIcon

                    text: row.modelData.entryType === "image" ? "image" : row.modelData.entryType === "file" ? "folder" : "content_copy"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.small.scale(0.9).build()

                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.padding.small
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    id: rowText

                    text: row.modelData.previewText ?? ""
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.small
                    elide: Text.ElideRight

                    anchors.left: rowIcon.right
                    anchors.leftMargin: Tokens.spacing.medium
                    anchors.right: deleteButton.left
                    anchors.rightMargin: Tokens.spacing.small
                    anchors.verticalCenter: parent.verticalCenter
                }

                IconButton {
                    id: deleteButton

                    icon: "close"
                    type: IconButton.Text
                    radius: Tokens.rounding.full
                    radiusMorph: false
                    // Stay visible while hovered directly: pointer over the
                    // button leaves the row MouseArea, dropping containsMouse.
                    // enabled gated the same way so the invisible button can't
                    // swallow clicks meant for the row.
                    opacity: rowState.containsMouse || deleteButton.hovered ? 0.8 : 0
                    enabled: rowState.containsMouse || deleteButton.hovered

                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.padding.extraSmall
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: Clipboard.removeAt(row.modelData.index)
                }
            }
        }

        RowLayout {
            Layout.topMargin: Tokens.spacing.extraSmall
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            TextButton {
                Layout.fillWidth: true

                text: Tr.tr("Open full history")
                onClicked: {
                    root.popouts.hasCurrent = false;
                    const state = ShellState.forActive();
                    state.clipboard = true;
                }
            }

            // Destructive, so two-step: first click arms, second within 3s clears.
            TextButton {
                Layout.fillWidth: true

                type: TextButton.Text
                text: root.clearArmed ? Tr.tr("Confirm clear") : Tr.tr("Clear all")
                label.color: Colours.palette.m3error
                onClicked: {
                    if (root.clearArmed) {
                        Clipboard.clearHistory();
                        root.clearArmed = false;
                    } else {
                        root.clearArmed = true;
                        clearArmTimer.restart();
                    }
                }
            }
        }

        Timer {
            id: clearArmTimer

            interval: 3000
            onTriggered: root.clearArmed = false
        }
    }
}
