import QtQuick
import "root:/modules/common"

/**
 * Text in the bar. Carries the font and the legibility shadow from Glass.css:
 *
 *   * { font-family: "Maple Mono NF CN"; font-weight: 500; font-size: 12px; }
 *   text-shadow: 0 1px 3px rgba(0, 0, 0, 0.55);
 *
 * Qt has no text-shadow, so the shadow is a second copy of the glyphs painted
 * one pixel down in translucent black. At 12px that reads the same as the CSS
 * blur radius without costing a layer/blur pass per module.
 */
Item {
    id: root

    property alias text: label.text
    property color color: Glass.textGlass
    property bool shadowed: true
    property int pixelSize: Glass.fontSize
    property string family: Glass.fontFamily
    property alias font: label.font
    property alias horizontalAlignment: label.horizontalAlignment
    property alias wrapMode: label.wrapMode
    property alias elide: label.elide
    property alias maximumLineCount: label.maximumLineCount
    property alias lineHeight: label.lineHeight

    // Whole-pixel size. NativeRendering only rasterises crisply on the pixel
    // grid, and a fractional height here propagates a half-pixel offset up
    // through every centred layout above.
    implicitWidth: Math.ceil(label.implicitWidth)
    implicitHeight: Math.ceil(label.implicitHeight)

    // Qt has no text-shadow. Glass.css asks for `0 1px 3px rgba(0,0,0,.55)`,
    // so this approximates the blur with two offset copies at low alpha - one
    // directly beneath for the drop, one spread for the halo. A single hard
    // copy reads as a smear at 12px rather than as depth.
    Repeater {
        model: root.shadowed ? [
            {
                dx: 0,
                dy: 1,
                a: root.pixelSize >= 12 ? 0.50 : 0.38
            },
            {
                dx: 0,
                dy: 2,
                a: root.pixelSize >= 12 ? 0.22 : 0.16
            }
        ] : []

        delegate: Text {
            required property var modelData

            text: label.text
            font: label.font
            color: Qt.rgba(0, 0, 0, modelData.a)
            width: label.width
            height: label.height
            horizontalAlignment: label.horizontalAlignment
            verticalAlignment: label.verticalAlignment
            x: label.x + modelData.dx
            y: label.y + modelData.dy
            renderType: Text.NativeRendering
        }
    }

    Text {
        id: label

        // Elide only engages against a CONSTRAINED width. Without this the
        // inner Text keeps its natural size and simply overflows the item -
        // which is how a long track title ran straight through the pill.
        // implicitWidth above still reports the natural size, so layouts that
        // do not clamp are unaffected.
        width: root.width > 0 ? root.width : implicitWidth
        color: root.color
        renderType: Text.NativeRendering
        verticalAlignment: Text.AlignVCenter

        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: Glass.fontWeight
        // Full hinting snaps stems to the pixel grid - this is the difference
        // between Qt text and pango text at 12px.
        font.hintingPreference: Font.PreferFullHinting
        font.kerning: false
        // §4: tabular figures, so clocks, percentages and timers do not
        // reflow as digits change width.
        font.features: ({
                tnum: 1
            })
    }
}
