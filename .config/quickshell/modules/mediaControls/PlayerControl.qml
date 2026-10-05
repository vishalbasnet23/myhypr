import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets

/**
 * One player card: art, track text, seek bar, transport buttons.
 *
 * Design follows MainstreamOS/dots-hyprland's mediaControls, but it is written
 * against the widgets this config actually has (StyledText, RippleButton,
 * StyledRectangularShadow). Theirs needs StyledSlider, StyledProgressBar,
 * StyledImage, StyledBlurEffect, WaveVisualizer and ColorQuantizer, none of
 * which exist here.
 */
Item {
    id: root

    required property MprisPlayer player
    property bool isActive: MprisController.activePlayer === root.player

    // MaterialSymbol resolves Appearance.font.family.iconFont, which is set to
    // "FiraConde Nerd Font" — a typo for FiraCode, so it falls back to Noto Sans
    // and icon names render as literal words. Material Symbols is not installed
    // either (fc-list finds 0). So the transport glyphs come straight from a
    // Nerd Font here, using Font Awesome codepoints that every Nerd Font build
    // has carried since v1.
    readonly property string iconFont: "FiraCode Nerd Font"
    readonly property string iconPlay: ""
    readonly property string iconPause: ""
    readonly property string iconPrevious: ""
    readonly property string iconNext: ""

    readonly property real artSize: 96
    readonly property real cardPadding: 14

    implicitWidth: 420
    implicitHeight: artSize + cardPadding * 2

    // MPRIS position is not pushed by the player; it has to be re-read. Poking
    // the notify signal is what forces the property to update, and it only runs
    // while this player is actually playing and the popup is on screen.
    Timer {
        running: root.visible && root.player?.isPlaying && root.player?.positionSupported
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    StyledRectangularShadow {
        target: card
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Appearance.rounding.normal
        // Appearance.colors.colLayer1/2 carry the shell-wide transparency, which
        // is fine for a fullscreen overview but unreadable for a small popup
        // floating over a browser. Build the card off the opaque window
        // background instead and keep only a hint of translucency.
        color: ColorUtils.transparentize(ColorUtils.mix(Appearance.m3colors.m3windowBackground, root.isActive ? Appearance.m3colors.m3layerBackground2 : Appearance.m3colors.m3layerBackground1, 0.88), 0.04)
        border.width: 1
        border.color: root.isActive ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.m3colors.m3borderSecondary, 0.4)

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: MprisController.setActivePlayer(root.player)
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: root.cardPadding
            spacing: root.cardPadding

            ClippingRectangle {
                Layout.preferredWidth: root.artSize
                Layout.preferredHeight: root.artSize
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready
                }

                // Placeholder for players that publish no cover art.
                StyledText {
                    anchors.centerIn: parent
                    visible: !art.visible
                    text: "" // nf-fa-music
                    font.family: root.iconFont
                    font.pixelSize: Glass.fontBig
                    color: Appearance.colors.colSubtext
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || "Unknown Title"
                    font.pixelSize: Appearance.font.pixelSize.textLarge
                    color: Appearance.m3colors.m3primaryText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.player?.trackArtist || "Unknown Artist"
                    font.pixelSize: Appearance.font.pixelSize.textSmall
                    color: Appearance.m3colors.m3secondaryText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.player?.identity ?? ""
                    font.pixelSize: Appearance.font.pixelSize.textSmall
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Item {
                    Layout.fillHeight: true
                }

                // Seek bar. Hidden entirely for players that do not report a
                // usable length (many browser players), rather than showing a
                // bar that never moves.
                Rectangle {
                    id: seekTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    visible: (root.player?.lengthSupported ?? false) && (root.player?.length ?? 0) > 0
                    radius: Appearance.rounding.full
                    color: Appearance.colors.colLayer2Hover

                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        color: Appearance.colors.colPrimary
                        width: {
                            const len = root.player?.length ?? 0;
                            if (len <= 0)
                                return 0;
                            const frac = Math.max(0, Math.min(1, (root.player?.position ?? 0) / len));
                            return parent.width * frac;
                        }

                        Behavior on width {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6 // easier to hit than 4px
                        enabled: root.player?.canSeek ?? false
                        onClicked: event => {
                            const len = root.player?.length ?? 0;
                            if (len > 0)
                                root.player.position = (event.x / seekTrack.width) * len;
                        }
                    }
                }

                RowLayout {
                    Layout.topMargin: 4
                    spacing: 4

                    RippleButton {
                        implicitWidth: 34
                        implicitHeight: 34
                        buttonRadius: Appearance.rounding.full
                        enabled: root.player?.canGoPrevious ?? false
                        onClicked: root.player.previous()
                        contentItem: StyledText {
                            text: root.iconPrevious
                            font.family: root.iconFont
                            font.pixelSize: Appearance.font.pixelSize.textMedium
                            color: Appearance.m3colors.m3primaryText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    RippleButton {
                        implicitWidth: 42
                        implicitHeight: 42
                        buttonRadius: Appearance.rounding.full
                        toggled: root.player?.isPlaying ?? false
                        enabled: root.player?.canTogglePlaying ?? false
                        onClicked: root.player.togglePlaying()
                        contentItem: StyledText {
                            text: (root.player?.isPlaying ?? false) ? root.iconPause : root.iconPlay
                            font.family: root.iconFont
                            font.pixelSize: Appearance.font.pixelSize.textLarge
                            color: (root.player?.isPlaying ?? false) ? Appearance.m3colors.m3accentPrimaryText : Appearance.m3colors.m3primaryText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    RippleButton {
                        implicitWidth: 34
                        implicitHeight: 34
                        buttonRadius: Appearance.rounding.full
                        enabled: root.player?.canGoNext ?? false
                        onClicked: root.player.next()
                        contentItem: StyledText {
                            text: root.iconNext
                            font.family: root.iconFont
                            font.pixelSize: Appearance.font.pixelSize.textMedium
                            color: Appearance.m3colors.m3primaryText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        visible: seekTrack.visible
                        text: {
                            const fmt = s => {
                                if (!isFinite(s) || s < 0)
                                    return "0:00";
                                const m = Math.floor(s / 60);
                                const sec = Math.floor(s % 60);
                                return `${m}:${sec.toString().padStart(2, "0")}`;
                            };
                            return `${fmt(root.player?.position ?? 0)} / ${fmt(root.player?.length ?? 0)}`;
                        }
                        font.pixelSize: Appearance.font.pixelSize.textSmall
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
