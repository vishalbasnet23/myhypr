import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "root:/modules/common"
import "root:/modules/drawers"
import ".."

/**
 * Battery: level, time remaining, and the power-profile selector.
 *
 * Layout follows the reference's battery popout - heading, big accent value,
 * caption, then a segmented control.
 *
 * The profile selector is DISABLED on this machine and says why:
 * power-profiles-daemon.service is masked (symlinked to /dev/null) because TLP
 * owns power management, and the two conflict. DESIGN.md §7 requires a
 * disabled control to explain itself rather than silently doing nothing.
 */
ColumnLayout {
    id: root

    property int preferredWidth: 260

    readonly property var dev: UPower.displayDevice
    readonly property int pct: Math.round((dev?.percentage ?? 0) * 100)
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
    readonly property bool profilesAvailable: PowerProfiles.profile !== undefined && !profilesMasked
    // UPower reports no profile at all when the daemon cannot start.
    readonly property bool profilesMasked: !PowerProfiles.hasPerformanceProfile && PowerProfiles.profile === undefined

    spacing: Glass.spaceS

    function remaining() {
        const d = root.dev;
        if (!d)
            return "";
        const secs = root.charging ? d.timeToFull : d.timeToEmpty;
        if (!secs || secs <= 0)
            return root.charging ? "Charging" : "";
        const h = Math.floor(secs / 3600);
        const m = Math.floor((secs % 3600) / 60);
        const t = h > 0 ? `${h} h ${m} min` : `${m} min`;
        return root.charging ? `About ${t} until full` : `About ${t} left`;
    }

    PopoutHeader {
        text: "Battery"
    }

    BarText {
        text: `${root.pct}%`
        color: root.pct <= 15 ? Glass.critical : Glass.accent
        pixelSize: Glass.fontBig
    }

    BarText {
        text: root.remaining()
        color: Glass.textDim
        pixelSize: Glass.fontMeta
        visible: text !== ""
        elide: Text.ElideRight
        Layout.fillWidth: true
    }

    // ---- power profile, segmented ----
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Glass.spaceXs
        spacing: Glass.spaceXs
        opacity: root.profilesAvailable ? 1 : 0.4

        Repeater {
            model: [
                {
                    id: "power-saver",
                    glyph: 0xF06C,
                    name: "Power saver"
                },
                {
                    id: "balanced",
                    glyph: 0xF24E,
                    name: "Balanced"
                },
                {
                    id: "performance",
                    glyph: 0xF0E7,
                    name: "Performance"
                }
            ]

            delegate: Rectangle {
                required property var modelData

                readonly property bool active: root.profilesAvailable && PowerProfile.toString(PowerProfiles.profile).toLowerCase().replace(" ", "-") === modelData.id

                Layout.fillWidth: true
                implicitHeight: Glass.hitTarget
                // §7: active state changes SHAPE as well as fill.
                radius: active ? Glass.itemRadius : height / 2
                color: active ? Glass.accent : ma.containsMouse && root.profilesAvailable ? Glass.uiHover : Glass.cardLayer

                Behavior on radius {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                Behavior on color {
                    CAnim {}
                }

                BarText {
                    anchors.centerIn: parent
                    text: String.fromCodePoint(modelData.glyph)
                    color: parent.active ? Glass.crust : Glass.textGlass
                }

                MouseArea {
                    id: ma

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.profilesAvailable
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: PowerProfiles.profile = modelData.id
                }
            }
        }
    }

    BarText {
        visible: !root.profilesAvailable
        text: "Power profiles unavailable — power-profiles-daemon is masked because TLP is managing power."
        color: Glass.textDim
        pixelSize: Glass.fontMeta
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.maximumWidth: root.preferredWidth
    }
}
