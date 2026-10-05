import QtQuick
import "root:/modules/common"

/**
 * Inner card. DESIGN.md §2: card layer over the panel tint, NO border, and
 * nesting stops here - no cards inside cards.
 *
 * Radius is the pillRadius step from §5's family rather than the literal
 * `inner = outer - padding` (20 - 16 = 4), which would read as a square at
 * this size. Flagged in the audit.
 */
Rectangle {
    id: root

    default property alias content: inner.data
    property int padding: Glass.cardPadding

    color: Glass.cardLayer
    radius: Glass.pillRadius

    Item {
        id: inner

        anchors.fill: parent
        anchors.margins: root.padding
    }
}
