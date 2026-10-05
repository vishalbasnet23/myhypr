pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.services

StyledRect {
    id: root

    property string text
    property bool show

    anchors.verticalCenter: parent.verticalCenter
    anchors.right: parent.left
    anchors.rightMargin: Tokens.spacing.small

    z: 1000
    visible: opacity > 0
    opacity: show ? 1 : 0

    color: Colours.palette.m3inverseSurface
    radius: Tokens.rounding.small

    implicitWidth: label.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: label.implicitHeight + Tokens.padding.extraSmall * 2

    StyledText {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: Colours.palette.m3inverseOnSurface
        font: Tokens.font.label.small
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
