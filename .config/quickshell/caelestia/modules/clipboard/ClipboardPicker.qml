pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

// Clipboard history picker UI. History capture and paste actions live in the
// Clipboard service; this is a per-screen Overlay window toggled through the
// ScreenState `clipboard` bool, so the stock `caelestia shell drawers toggle
// clipboard` IPC (and any keybind calling it) drives it. Ported from the
// omacom/omarchy clipboard plugin.

Scope {
    Variants {
        model: Screens.screens

        StyledWindow {
            id: win

            required property ShellScreen modelData

            readonly property ScreenState screenState: ShellState.forScreen(modelData)
            readonly property bool opened: screenState?.clipboard ?? false
            readonly property var currentRow: {
                const rows = rowModel.values;
                return list.currentIndex >= 0 && list.currentIndex < rows.length ? rows[list.currentIndex] : null;
            }

            property bool clearArmed: false

            function close(): void {
                win.clearArmed = false;
                win.screenState.clipboard = false;
            }

            // mode: "paste" | "copy" | "open". Close first so focus returns to
            // the target app before the synthetic paste lands.
            function act(mode: string, row: var): void {
                if (!row)
                    return;
                win.close();
                if (mode === "open")
                    Clipboard.openEntry(row);
                else if (mode === "copy")
                    Clipboard.copy(row);
                else
                    Clipboard.paste(row);
            }

            function select(delta: int): void {
                if (list.count === 0)
                    return;
                list.currentIndex = (list.currentIndex + delta + list.count) % list.count;
                list.positionViewAtIndex(list.currentIndex, ListView.Contain);
            }

            function selectAbsolute(index: int): void {
                if (list.count === 0)
                    return;
                list.currentIndex = Math.max(0, Math.min(index, list.count - 1));
                list.positionViewAtIndex(list.currentIndex, ListView.Contain);
            }

            onOpenedChanged: {
                if (!opened)
                    return;
                // Exclusive keyboard focus would fight the drawers window; close them.
                screenState.launcher = false;
                screenState.session = false;
                screenState.dashboard = false;
                screenState.sidebar = false;
                screenState.utilities = false;
                win.clearArmed = false;
                search.text = "";
                Qt.callLater(() => search.forceActiveFocus());
            }

            Timer {
                id: clearArmTimer

                interval: 3000
                onTriggered: win.clearArmed = false
            }

            HyprlandFocusGrab {
                active: win.opened && win.visible
                windows: [win]
                onCleared: win.close()
            }

            screen: modelData
            name: "clipboard"
            visible: win.opened

            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: win.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.palette.m3scrim, 0.32)

                MouseArea {
                    anchors.fill: parent
                    onClicked: win.close()
                }
            }

            StyledRect {
                id: card

                width: Math.min(900, win.width - Tokens.padding.extraLarge * 2)
                height: Math.min(600, win.height - Tokens.padding.extraLarge * 2)
                anchors.centerIn: parent

                // Opaque on purpose: the translucent surface made history text
                // unreadable over bright windows.
                color: Colours.palette.m3surfaceContainer
                radius: Tokens.rounding.extraLarge

                // Swallow clicks so they don't fall through to the scrim.
                MouseArea {
                    anchors.fill: parent
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    SearchBar {
                        id: search

                        width: parent.width

                        placeholderText: Tr.tr("Search clipboard history")

                        // BeforeItem so Delete/PageUp/Return-with-modifiers reach us
                        // instead of being eaten by the text field; everything else
                        // falls through to normal text editing.
                        Keys.priority: Keys.BeforeItem
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Up) {
                                win.select(-1);
                            } else if (event.key === Qt.Key_Down) {
                                win.select(1);
                            } else if (event.key === Qt.Key_PageUp) {
                                win.select(-6);
                            } else if (event.key === Qt.Key_PageDown) {
                                win.select(6);
                            } else if (event.key === Qt.Key_Home) {
                                win.selectAbsolute(0);
                            } else if (event.key === Qt.Key_End) {
                                win.selectAbsolute(list.count - 1);
                            } else if (event.key === Qt.Key_Escape) {
                                if (search.text)
                                    search.clear();
                                else
                                    win.close();
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                const row = win.currentRow;
                                if (event.modifiers & Qt.AltModifier)
                                    win.act("open", row);
                                else if (event.modifiers & Qt.ShiftModifier)
                                    win.act("copy", row);
                                else
                                    win.act("paste", row);
                            } else if (event.key === Qt.Key_Delete) {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    if (win.clearArmed) {
                                        Clipboard.clearHistory();
                                        win.clearArmed = false;
                                    } else {
                                        win.clearArmed = true;
                                        clearArmTimer.restart();
                                    }
                                } else if (win.currentRow) {
                                    Clipboard.removeAt(win.currentRow.index);
                                }
                            } else {
                                return;
                            }
                            event.accepted = true;
                        }

                        onTextChanged: list.currentIndex = 0
                    }

                    Row {
                        width: parent.width
                        height: parent.height - search.height - hints.height - parent.spacing * 2
                        spacing: Tokens.spacing.medium

                        StyledListView {
                            id: list

                            width: parent.width / 2 - parent.spacing / 2
                            height: parent.height
                            clip: true

                            spacing: Tokens.spacing.extraSmall
                            boundsBehavior: Flickable.StopAtBounds

                            preferredHighlightBegin: 0
                            preferredHighlightEnd: height
                            highlightRangeMode: ListView.ApplyRange

                            model: ScriptModel {
                                id: rowModel

                                values: Clipboard.displayRows(search.text.trim(), 50)
                                // currentIndex starts at -1; keep it on a real row
                                // so the highlight and preview pane have something to show.
                                onValuesChanged: list.currentIndex = values.length === 0 ? -1 : Math.max(0, Math.min(list.currentIndex, values.length - 1))
                            }

                            highlightFollowsCurrentItem: false
                            highlight: StyledRect {
                                radius: Tokens.rounding.large
                                color: Colours.palette.m3onSurface
                                opacity: 0.08

                                y: list.currentItem?.y ?? 0
                                implicitWidth: list.width
                                implicitHeight: list.currentItem?.implicitHeight ?? 0

                                Behavior on y {
                                    Anim {}
                                }
                            }

                            delegate: Item {
                                id: rowItem

                                required property var modelData
                                required property int index

                                implicitHeight: Tokens.sizes.launcher.itemHeight
                                width: ListView.view.width

                                StateLayer {
                                    radius: Tokens.rounding.large
                                    onClicked: {
                                        list.currentIndex = rowItem.index;
                                        win.act("paste", rowItem.modelData);
                                    }
                                }

                                Image {
                                    id: thumb

                                    readonly property string thumbPath: rowItem.modelData.previewImage ?? ""

                                    visible: thumbPath.length > 0
                                    source: visible ? `file://${thumbPath}` : ""
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true

                                    anchors.left: parent.left
                                    anchors.leftMargin: Tokens.padding.medium
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: parent.height - Tokens.padding.small * 2
                                    width: visible ? height : 0
                                }

                                MaterialIcon {
                                    id: typeIcon

                                    visible: !thumb.visible
                                    text: rowItem.modelData.entryType === "image" ? "image" : rowItem.modelData.entryType === "file" ? "folder" : "content_copy"
                                    color: Colours.palette.m3onSurfaceVariant
                                    fontStyle: Tokens.font.icon.builders.medium.scale(0.9).build()

                                    anchors.left: parent.left
                                    anchors.leftMargin: Tokens.padding.medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: rowItem.modelData.previewText ?? ""
                                    font: Tokens.font.body.medium
                                    color: Colours.palette.m3onSurface
                                    opacity: rowItem.modelData.entryType === "text" ? 1 : 0.72
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter

                                    anchors.left: thumb.visible ? thumb.right : typeIcon.right
                                    anchors.leftMargin: Tokens.spacing.medium
                                    anchors.right: deleteButton.left
                                    anchors.rightMargin: Tokens.spacing.small
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                IconButton {
                                    id: deleteButton

                                    icon: "delete"
                                    type: IconButton.Text
                                    radius: Tokens.rounding.full
                                    radiusMorph: false
                                    opacity: list.currentIndex === rowItem.index ? 0.72 : 0

                                    anchors.right: parent.right
                                    anchors.rightMargin: Tokens.padding.small
                                    anchors.verticalCenter: parent.verticalCenter

                                    onClicked: Clipboard.removeAt(rowItem.modelData.index)
                                }
                            }
                        }

                        Item {
                            id: previewPane

                            readonly property var row: win.currentRow

                            width: parent.width / 2 - parent.spacing / 2
                            height: parent.height
                            clip: true

                            Rectangle {
                                width: 1
                                height: parent.height
                                color: Colours.palette.m3outline
                                opacity: 0.28
                            }

                            StyledText {
                                visible: previewPane.row && !previewPane.row.previewImage
                                text: previewPane.row ? previewPane.row.fullText : ""
                                font: Tokens.font.body.small
                                color: Colours.palette.m3onSurface
                                wrapMode: Text.WrapAnywhere
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignTop

                                anchors.fill: parent
                                anchors.leftMargin: Tokens.padding.large
                                anchors.topMargin: Tokens.padding.extraSmall
                                anchors.bottomMargin: Tokens.padding.extraSmall
                            }

                            Image {
                                visible: previewPane.row && previewPane.row.previewImage.length > 0
                                source: visible ? `file://${previewPane.row.previewImage}` : ""
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                smooth: true

                                anchors.fill: parent
                                anchors.leftMargin: Tokens.padding.large
                                anchors.topMargin: Tokens.padding.extraSmall
                                anchors.bottomMargin: Tokens.padding.extraSmall
                            }
                        }
                    }

                    StyledText {
                        id: hints

                        width: parent.width
                        text: win.clearArmed ? Tr.tr("Press Shift+Del again to erase all history") : Tr.tr("Enter paste · Shift+Enter copy · Alt+Enter open · Del remove · Shift+Del clear")
                        color: win.clearArmed ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                StyledText {
                    visible: list.count === 0
                    text: Clipboard.count === 0 ? Tr.tr("Clipboard history is empty") : Tr.tr("No matching entries")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.large
                    anchors.centerIn: parent
                }
            }
        }
    }
}
