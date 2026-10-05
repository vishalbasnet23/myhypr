import QtQuick
import QtQuick.Layouts
import "root:/modules/common"
import ".."

/**
 * One labelled line inside a popout, optionally with a meter.
 *
 * The meter is the popout's whole reason for existing: in the bar a module can
 * only afford "62% 󰍛", but here there is room to show the number AND how full
 * it is, which is the thing the drawer could never do.
 */
RowLayout {
    id: root

    property string label: ""
    property string value: ""
    property string icon: ""
    /// 0-1; negative disables the meter.
    property real fraction: -1
    property color meterColour: Glass.accent

    spacing: 10
    Layout.fillWidth: true

    BarText {
        text: root.icon
        color: Glass.textDim
        visible: root.icon !== ""
        Layout.preferredWidth: root.icon !== "" ? 16 : 0
    }

    BarText {
        text: root.label
        color: Glass.textDim
        Layout.minimumWidth: 86
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 5
        Layout.alignment: Qt.AlignVCenter
        visible: root.fraction >= 0
        radius: height / 2
        color: Glass.glassRaised

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.fraction))
            height: parent.height
            radius: parent.radius
            color: root.meterColour

            Behavior on width {
                Anim { type: Anim.Standard }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        visible: root.fraction < 0
    }

    BarText {
        text: root.value
        color: Glass.textGlass
        Layout.minimumWidth: 96
        horizontalAlignment: Text.AlignRight
    }
}
