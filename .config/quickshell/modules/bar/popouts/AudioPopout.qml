import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "root:/modules/common"
import ".."

/**
 * Replaces waybar's group/audio drawer.
 *
 * waybar could only reveal the microphone as a second label, and volume was
 * scroll-only. Here both sinks get a real draggable slider plus the device
 * description that was previously buried in tooltip-format.
 *
 * Writes still go through scripts/Volume.sh so the OSD the rest of the desktop
 * shows stays identical - the slider is a nicer input to the same pipeline,
 * not a second one.
 */
ColumnLayout {
    id: root

    readonly property string home: Quickshell.env("HOME")

    spacing: 10
    // Layouts clobber implicitWidth, so the panel reads this instead.
    property int preferredWidth: 280

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    PopoutHeader {
        text: "Audio"
    }

    Slider {
        label: "Output"
        icon: "󰕾"
        node: Pipewire.defaultAudioSink
        onStep: up => Quickshell.execDetached(["bash", `${root.home}/.config/hypr/scripts/Volume.sh`, up ? "--inc" : "--dec"])
        onToggle: Quickshell.execDetached(["bash", `${root.home}/.config/hypr/scripts/Volume.sh`, "--toggle"])
    }

    Slider {
        label: "Input"
        icon: ""
        node: Pipewire.defaultAudioSource
        onStep: up => Quickshell.execDetached(["bash", `${root.home}/.config/hypr/scripts/Volume.sh`, up ? "--mic-inc" : "--mic-dec"])
        onToggle: Quickshell.execDetached(["bash", `${root.home}/.config/hypr/scripts/Volume.sh`, "--toggle-mic"])
    }

    component Slider: ColumnLayout {
        id: slider

        required property string label
        required property string icon
        required property PwNode node

        signal step(bool up)
        signal toggle

        readonly property int volume: Math.round((node?.audio?.volume ?? 0) * 100)
        readonly property bool muted: node?.audio?.muted ?? false

        spacing: 4
        Layout.fillWidth: true

        RowLayout {
            spacing: 8
            Layout.fillWidth: true

            BarText {
                text: slider.muted ? "󰖁" : slider.icon
                color: slider.muted ? Glass.textDim : Glass.textGlass

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: slider.toggle()
                }
            }

            BarText {
                text: slider.label
                color: Glass.textDim
            }

            Item {
                Layout.fillWidth: true
            }

            BarText {
                text: `${slider.volume}%`
                color: slider.muted ? Glass.textDim : Glass.textGlass
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Glass.glassRaised

            Rectangle {
                width: parent.width * Math.min(1, slider.volume / 100)
                height: parent.height
                radius: parent.radius
                color: slider.muted ? Glass.overlay0 : Glass.accent

                Behavior on width {
                    Anim { type: Anim.DefaultEffects }
                }
            }

            WheelHandler {
                onWheel: event => slider.step(event.angleDelta.y > 0)
            }
        }

        BarText {
            text: slider.node?.description ?? slider.node?.nickname ?? ""
            color: Glass.textDim
            pixelSize: Glass.fontMeta
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.maximumWidth: 260
        }
    }
}
