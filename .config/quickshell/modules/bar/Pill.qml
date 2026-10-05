import QtQuick
import QtQuick.Layouts
import "root:/modules/common"

/**
 * One of the three glass pills - the QML twin of Glass.css:
 *
 *   .modules-left, .modules-center, .modules-right {
 *     margin: 0px 8px; margin-top: 4px;
 *     padding: 2px 6px;
 *     background: rgba(232, 238, 245, 0.13);
 *     border: 1px solid rgba(255, 255, 255, 0.22);
 *     border-radius: 14px;
 *     box-shadow: 0 10px 26px -14px rgba(0, 0, 0, 0.9);
 *   }
 *
 * The drop shadow is faked with a stack of rounded rectangles rather than a
 * blur effect: the bar layer is already being blurred by Hyprland, and a
 * MultiEffect on top of that costs a full offscreen pass for something only a
 * few pixels tall.
 */
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing

    implicitWidth: 2 * Math.ceil((row.implicitWidth + Glass.pillPaddingH * 2) / 2)
    implicitHeight: 2 * Math.ceil((row.implicitHeight + Glass.pillPaddingV * 2) / 2)

    color: Glass.glassFill
    radius: Glass.pillRadius
    border.width: 1
    border.color: Glass.glassBorder

    // The lit top edge. In CSS this is the inset half of the box-shadow; here
    // it is a 1px highlight inside the border, which is what that inset draws.
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        anchors.topMargin: 1
        height: 1
        radius: 1
        color: Glass.glassHighlight
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: Glass.pillPaddingH
        anchors.rightMargin: Glass.pillPaddingH
        anchors.topMargin: Glass.pillPaddingV
        anchors.bottomMargin: Glass.pillPaddingV

        spacing: Glass.barSpacing
    }
}
