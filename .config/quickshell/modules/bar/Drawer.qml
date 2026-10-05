import QtQuick
import QtQuick.Layouts
import "root:/modules/common"

/**
 * waybar's group/<name> with a `drawer` block - the hover-expand containers
 * used by group/time, group/notify, group/audio and group/mobo_drawer.
 *
 * waybar semantics, from ModulesGroups:
 *   - the FIRST module in `children-class` is always visible
 *   - the rest reveal on hover, animating over `transition-duration`
 *   - `transition-left-to-right` picks which side they grow from
 *
 * Glass.css deliberately leaves these containers transparent so they inherit
 * the pill behind them rather than painting a second surface on top.
 */
Item {
    id: root

    /// Always-visible module (waybar's children-class).
    property alias handle: handleSlot.data
    /// Modules revealed on hover.
    default property alias drawered: drawerRow.data
    /// waybar drawer.transition-duration
    property int duration: Glass.animDrawer
    /// waybar drawer.transition-left-to-right
    property bool leftToRight: true

    readonly property bool open: hover.hovered

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    Layout.alignment: Qt.AlignVCenter

    HoverHandler {
        id: hover
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: 0
        layoutDirection: root.leftToRight ? Qt.LeftToRight : Qt.RightToLeft

        Item {
            id: handleSlot

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }

        // Clipped so the revealed modules slide out from behind the handle
        // rather than popping into existence.
        Item {
            id: clip

            Layout.alignment: Qt.AlignVCenter
            clip: true
            implicitHeight: drawerRow.implicitHeight
            implicitWidth: root.open ? drawerRow.implicitWidth : 0

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: root.duration
                    easing.type: Easing.OutCubic
                }
            }

            RowLayout {
                id: drawerRow

                spacing: Glass.barSpacing
                anchors.verticalCenter: parent.verticalCenter
                // Grow from the handle side.
                anchors.left: root.leftToRight ? parent.left : undefined
                anchors.right: root.leftToRight ? undefined : parent.right
            }
        }
    }
}
