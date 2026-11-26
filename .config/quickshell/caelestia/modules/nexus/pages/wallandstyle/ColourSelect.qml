pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common

// mydots: nightwire flavour picker. Each flavour is a dark/light pair under
// caelestia's data/schemes/nightwire/<flavour>/ (installed by
// .config/quickshell/nightwire-light/install.sh), so this page only picks the
// flavour and the "Dark theme" toggle keeps choosing the mode.
PageBase {
    id: root

    readonly property string schemeName: "nightwire"
    // Display order + blurb. Flavours found on disk but missing here still
    // show up, after these, with no blurb.
    readonly property var known: ({
            neon: Tr.tr("Hot pink, electric teal and acid lime. The original."),
            synthwave: Tr.tr("Violet, sunset amber and cyan on deep purple."),
            acid: Tr.tr("Toxic green leads, pink second, amber highlights."),
            glacier: Tr.tr("Ice blue, lavender and aqua. The calm one."),
            redline: Tr.tr("Signal red, amber and a cold teal on wine black."),
            amber: Tr.tr("CRT amber and orange with a sage green accent."),
            deepsea: Tr.tr("Bioluminescent teal, ocean blue and a gold accent."),
            moss: Tr.tr("Lime moss, teal and warm orange on forest black."),
            cobalt: Tr.tr("Electric blue, cyan and a sharp yellow accent."),
            chrome: Tr.tr("Near-monochrome silver with a cyan accent.")
        })
    property var flavours: []

    title: Tr.tr("Colours")
    isSubPage: true

    function apply(flavour: string): void {
        Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-n", schemeName, "-f", flavour]);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        // Card colours come from `scheme list`, which reports the current mode,
        // so re-list whenever the mode flips.
        Connections {
            target: Colours

            function onLightChanged(): void {
                listProc.running = true;
            }
        }

        Process {
            id: listProc

            running: true
            command: ["caelestia", "scheme", "list"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const data = JSON.parse(text)[root.schemeName] ?? {};
                    const order = Object.keys(root.known);
                    const rank = f => order.includes(f) ? order.indexOf(f) : order.length;
                    root.flavours = Object.entries(data).map(([flavour, colours]) => ({
                                flavour,
                                colours
                            })).sort((a, b) => rank(a.flavour) - rank(b.flavour) || a.flavour.localeCompare(b.flavour));
                }
            }
        }

        ToggleRow {
            first: true
            text: Tr.tr("Dark theme")
            subtext: Tr.tr("Every flavour has a dark and a light version")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.small
            text: Tr.tr("Nightwire flavours")
            font: Tokens.font.title.small
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.medium

            Repeater {
                model: root.flavours

                StyledRect {
                    id: card

                    required property var modelData
                    readonly property var c: modelData.colours
                    readonly property bool active: Colours.scheme === root.schemeName && Colours.flavour === modelData.flavour

                    function col(key: string): color {
                        return `#${c[key]}`;
                    }

                    Layout.fillWidth: true
                    implicitHeight: cardLayout.implicitHeight + Tokens.padding.large * 2

                    radius: Tokens.rounding.large
                    color: col("surfaceContainer")
                    border.width: active ? 2 : 1
                    border.color: active ? col("primary") : col("outlineVariant")

                    ColumnLayout {
                        id: cardLayout

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.large
                        spacing: Tokens.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            Repeater {
                                model: ["primary", "secondary", "tertiary"]

                                StyledRect {
                                    required property string modelData

                                    implicitWidth: modelData === "primary" ? 36 : 18
                                    implicitHeight: 18
                                    radius: Tokens.rounding.full
                                    color: card.col(modelData)
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            MaterialIcon {
                                visible: card.active
                                text: "check_circle"
                                color: card.col("primary")
                                fill: 1
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: card.modelData.flavour.slice(0, 1).toUpperCase() + card.modelData.flavour.slice(1)
                            color: card.col("onSurface")
                            font: Tokens.font.title.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: root.known[card.modelData.flavour] ?? ""
                            color: card.col("onSurfaceVariant")
                            font: Tokens.font.body.small
                            wrapMode: Text.WordWrap
                        }
                    }

                    StateLayer {
                        radius: card.radius
                        color: card.col("onSurface")
                        onClicked: root.apply(card.modelData.flavour)
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.flavours.length === 0 && !listProc.running
            text: Tr.tr("No nightwire flavours found. Run nightwire-light/install.sh with sudo.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.medium
            wrapMode: Text.WordWrap
        }
    }
}
