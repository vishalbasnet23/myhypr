import QtQuick
import QtQuick.Layouts
import "root:/modules/common"
import "root:/modules/bar"
import "root:/modules/drawers"

/**
 * Tab strip: icon above label, with a short underline under the active tab.
 *
 * Matches the reference's structure (icon + label + underline indicator)
 * rather than the filled pill I had first. The underline animates its x and
 * width together with FastSpatial, so moving between labels of different
 * widths reads as one object travelling.
 *
 * Icons are Nerd Font glyphs, not Material Symbols - DESIGN.md §4 allows only
 * the bar's font.
 */
Item {
    id: root

    // Single source of truth, so the selection survives close/open and can be
    // driven from IPC or a keybind.
    property int current: ShellState.dashboardTab

    readonly property var tabs: [
        {
            label: "Dashboard",
            glyph: 0xF0A1D      // view-dashboard
        },
        {
            label: "Media",
            glyph: 0xF075A      // playlist-music
        },
        {
            label: "Performance",
            glyph: 0xF0D23      // speedometer
        },
        {
            label: "Weather",
            glyph: 0xF0599      // weather-partly-cloudy
        }
    ]

    implicitHeight: 52

    Row {
        id: row

        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.tabs

            delegate: Item {
                required property int index
                required property var modelData

                width: root.width / root.tabs.length
                height: root.height

                readonly property bool active: root.current === index

                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    BarText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: String.fromCodePoint(modelData.glyph)
                        pixelSize: Glass.fontTitle
                        color: active ? Glass.accent : Glass.textDim

                        Behavior on color {
                            CAnim {}
                        }
                    }

                    BarText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        pixelSize: Glass.fontMeta
                        color: active ? Glass.textGlass : Glass.textDim
                        elide: Text.ElideRight

                        Behavior on color {
                            CAnim {}
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.dashboardTab = index
                }
            }
        }
    }

    // Underline indicator
    Rectangle {
        readonly property Item target: row.children[root.current] ?? null

        x: (target?.x ?? 0) + (target?.width ?? 0) / 2 - width / 2
        width: Math.max(24, (target?.width ?? 0) * 0.5)
        height: 2
        radius: 1
        anchors.bottom: parent.bottom
        color: Glass.accent

        Behavior on x {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Behavior on width {
            Anim {
                type: Anim.FastSpatial
            }
        }
    }
}
