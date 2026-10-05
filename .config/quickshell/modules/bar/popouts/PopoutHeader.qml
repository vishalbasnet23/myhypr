import QtQuick
import QtQuick.Layouts
import "root:/modules/common"
import ".."

/**
 * Section title for a popout.
 *
 * Small and dim rather than large and bright: the panel is already separated
 * from everything else by its own glass edge, so a loud heading competes with
 * the content.
 *
 * No accent tick and no ALL CAPS - DESIGN.md §1.5 (no decoration that carries
 * no information), §3 (one accent, reserved for selection) and §4 (sentence
 * case).
 */
RowLayout {
    id: root

    property string text: ""

    spacing: 7
    Layout.fillWidth: true

    BarText {
        text: root.text
        color: Glass.subtext0
        pixelSize: Glass.fontMeta
        Layout.alignment: Qt.AlignVCenter
    }

    Item {
        Layout.fillWidth: true
    }
}
