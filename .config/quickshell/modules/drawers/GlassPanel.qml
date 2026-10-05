import QtQuick
import "root:/modules/common"

/**
 * The panel surface - same material as the bar's pill.
 *
 * Border, inset highlight and radius are taken from Glass.qml so they are
 * literally the same values the bar uses. Only the TINT differs, and that is
 * switchable while we decide:
 *
 *   Glass.panelTintLight = the bar's own rgba(232,238,245,0.13)
 *   Glass.panelTintDark  = rgba(26,28,44,0.30)
 *
 * Flip Glass.useLightPanelTint to compare.
 */
Rectangle {
    id: root

    default property alias content: inner.data

    color: Glass.panelSurface
    radius: Glass.panelRadius
    border.width: 1
    border.color: Glass.glassBorder

    Behavior on color {
        CAnim {}
    }

    // The lit top edge - the inset half of Glass.css's box-shadow, identical
    // to the bar pill's.
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: 1
        radius: 1
        color: Glass.glassHighlight
    }

    Item {
        id: inner

        anchors.fill: parent
    }
}
