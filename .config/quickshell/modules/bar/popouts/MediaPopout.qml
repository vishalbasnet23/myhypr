import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "root:/modules/common"
import "root:/services"
import ".."

/**
 * Now-playing panel: cover art, track details, a scrubbable seek bar and
 * transport controls.
 *
 * Layout follows caelestia-dots/shell's dashboard media card - art on the
 * left, details stacked beside it, controls under the seek bar - rebuilt
 * against our own tokens rather than copied, since that project is GPL-3.0
 * and its components are bound to its Material You config.
 */
ColumnLayout {
    id: root

    property int preferredWidth: 360

    readonly property int artSize: 84

    spacing: 12

    PopoutHeader {
        text: "Now playing"
    }

    // ---- art + details ----
    RowLayout {
        spacing: 12
        Layout.fillWidth: true

        Rectangle {
            id: artFrame

            implicitWidth: root.artSize
            implicitHeight: root.artSize
            radius: Glass.itemRadius + 2
            color: Glass.glassRaised
            border.width: 1
            border.color: Glass.glassBorder
            clip: true

            Image {
                id: art

                anchors.fill: parent
                anchors.margins: 1
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
                        radius: artFrame.radius - 1
                    }
                }
            }

            // Placeholder when the player exposes no artwork (most browsers).
            BarText {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: String.fromCodePoint(0xF001)   // music note
                color: Glass.textFaint
                pixelSize: Glass.fontBig
            }
        }

        ColumnLayout {
            spacing: 3
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            // Without a ceiling the natural width of a long track title
            // inflates this row past the panel edge - fillWidth alone does not
            // cap it, it only distributes slack.
            //   panel - 2*padding - art - row spacing
            Layout.maximumWidth: root.preferredWidth - 28 - root.artSize - 12

            BarText {
                text: Players.title !== "" ? Players.title : Players.identity
                color: Glass.textGlass
                pixelSize: Glass.fontTitle
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            BarText {
                text: Players.artist
                color: Glass.subtext1
                elide: Text.ElideRight
                visible: Players.artist !== ""
                Layout.fillWidth: true
            }

            BarText {
                text: Players.album
                color: Glass.textDim
                pixelSize: Glass.fontMeta
                elide: Text.ElideRight
                visible: Players.album !== ""
                Layout.fillWidth: true
            }

            Item {
                Layout.fillHeight: true
            }

            BarText {
                text: Players.identity
                color: Glass.textFaint
                pixelSize: Glass.fontMeta
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    // ---- seek bar ----
    ColumnLayout {
        spacing: 4
        Layout.fillWidth: true

        Rectangle {
            id: track

            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Glass.glassRaised

            Rectangle {
                id: fill

                width: parent.width * Players.progress
                height: parent.height
                radius: parent.radius
                color: Glass.accent

                Behavior on width {
                    enabled: !seek.pressed
                    NumberAnimation {
                        duration: 900
                        easing.type: Easing.Linear
                    }
                }
            }

            // Scrub handle, only while the bar can actually be seeked.
            Rectangle {
                visible: Players.lengthKnown
                width: 10
                height: 10
                radius: 5
                color: Glass.sel
                y: (parent.height - height) / 2
                x: Math.max(0, Math.min(parent.width - width, fill.width - width / 2))
                opacity: seek.containsMouse || seek.pressed ? 1 : 0

                Behavior on opacity {
                    Anim { type: Anim.DefaultEffects }
                }
            }

            MouseArea {
                id: seek

                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                enabled: Players.lengthKnown
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                function scrub(mx) {
                    Players.seekFraction(Math.max(0, Math.min(1, (mx + 6) / track.width)));
                }

                onPressed: mouse => scrub(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        scrub(mouse.x);
                }
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
    }

    // ---- transport ----
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 6

        Control {
            glyph: String.fromCodePoint(0xF04A)   // backward
            enabled: Players.active?.canGoPrevious ?? false
            onActivated: Players.previous()
        }

        Control {
            primary: true
            glyph: Players.playing ? String.fromCodePoint(0xF04C) : String.fromCodePoint(0xF04B)
            enabled: Players.active?.canTogglePlaying ?? false
            onActivated: Players.toggle()
        }

        Control {
            glyph: String.fromCodePoint(0xF04E)   // forward
            enabled: Players.active?.canGoNext ?? false
            onActivated: Players.next()
        }
    }

    component Control: Rectangle {
        id: ctl

        required property string glyph
        property bool primary: false

        signal activated

        implicitWidth: primary ? 38 : 32
        implicitHeight: primary ? 38 : 32
        radius: width / 2
        opacity: ctl.enabled ? 1 : 0.35
        color: primary ? (ma.containsMouse ? Qt.lighter(Glass.accent, 1.15) : Glass.accent) : (ma.containsMouse ? Glass.uiHover : Glass.glassRaised)

        Behavior on color {
            CAnim {}
        }

        BarText {
            anchors.centerIn: parent
            text: ctl.glyph
            color: ctl.primary ? "#ffffff" : Glass.textGlass
            pixelSize: ctl.primary ? 13 : 11
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
