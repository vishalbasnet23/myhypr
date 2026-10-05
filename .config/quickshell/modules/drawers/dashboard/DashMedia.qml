import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "root:/modules/common"
import "root:/modules/bar"
import "root:/modules/drawers"
import "root:/services"

/**
 * Media tab: wide art card on top, details card beneath.
 *
 * Deliberately NOT the bar's MediaPopout. That one is laid out for a 360px
 * popout - art beside the text - and stretching it to panel width put the art
 * under the title and let long track names overflow. The reference uses a
 * different arrangement at this size, so this is its own layout.
 */
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: Glass.cardGap
        visible: Players.hasPlayer

        // ---- art ----
        Card {
            Layout.fillWidth: true
            implicitHeight: 190
            padding: 0
            clip: true

            Image {
                id: art

                anchors.fill: parent
                source: Players.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: art.width
                        height: art.height
                        radius: Glass.pillRadius
                    }
                }
            }

            BarText {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: String.fromCodePoint(0xF001)
                color: Glass.textFaint
                pixelSize: Glass.fontBig
            }
        }

        // ---- details ----
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Glass.spaceXs

                BarText {
                    text: Players.title !== "" ? Players.title : Players.identity
                    color: Glass.textGlass
                    pixelSize: Glass.fontTitle
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                BarText {
                    text: {
                        const a = Players.artist;
                        const al = Players.album;
                        if (a === "" && al === "")
                            return Players.identity;
                        return al !== "" ? `${a}, from ${al}` : a;
                    }
                    color: Glass.textDim
                    pixelSize: Glass.fontMeta
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // progress
                Rectangle {
                    id: track

                    Layout.fillWidth: true
                    Layout.topMargin: Glass.spaceS
                    implicitHeight: 4
                    radius: 2
                    color: Glass.glassRaised

                    Rectangle {
                        width: parent.width * Players.progress
                        height: parent.height
                        radius: parent.radius
                        color: Glass.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -Glass.spaceM
                        enabled: Players.lengthKnown
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onPressed: mouse => Players.seekFraction((mouse.x + Glass.spaceM) / track.width)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    BarText {
                        text: Players.timeStr(Players.position)
                        color: Glass.textDim
                        pixelSize: Glass.fontMeta
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    BarText {
                        text: Players.lengthKnown ? Players.timeStr(Players.length) : "live"
                        color: Glass.textDim
                        pixelSize: Glass.fontMeta
                    }
                }

                // transport, left aligned as in the reference
                RowLayout {
                    Layout.topMargin: Glass.spaceS
                    spacing: Glass.spaceS

                    Control {
                        glyph: 0xF04A
                        enabled: Players.active?.canGoPrevious ?? false
                        onActivated: Players.previous()
                    }

                    Control {
                        primary: true
                        glyph: Players.playing ? 0xF04C : 0xF04B
                        enabled: Players.active?.canTogglePlaying ?? false
                        onActivated: Players.toggle()
                    }

                    Control {
                        glyph: 0xF04E
                        enabled: Players.active?.canGoNext ?? false
                        onActivated: Players.next()
                    }
                }
            }
        }
    }

    // §10 empty state: say what it means, not just that it is empty.
    BarText {
        anchors.centerIn: parent
        visible: !Players.hasPlayer
        text: "Nothing playing"
        color: Glass.textFaint
    }

    component Control: Rectangle {
        id: ctl

        property int glyph: 0
        property bool primary: false

        signal activated

        // §8: 32x32 minimum hit target.
        implicitWidth: primary ? 46 : Glass.hitTarget
        implicitHeight: Glass.hitTarget
        radius: height / 2
        opacity: ctl.enabled ? 1 : 0.4
        color: primary ? Glass.accent : ma.containsMouse ? Glass.uiHover : Glass.glassRaised

        Behavior on color {
            CAnim {}
        }

        BarText {
            anchors.centerIn: parent
            text: String.fromCodePoint(ctl.glyph)
            color: ctl.primary ? Glass.crust : Glass.textGlass
            pixelSize: Glass.fontMeta
        }

        MouseArea {
            id: ma

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: ctl.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (ctl.enabled)
                ctl.activated()
        }
    }
}
