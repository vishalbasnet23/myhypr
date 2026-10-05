import QtQuick
import QtQuick.Shapes
import "root:/modules/common"
import "root:/modules/bar"

/**
 * A progress ring.
 *
 * Drawn with QtQuick.Shapes rather than a Canvas: Shapes is retained-mode and
 * GPU-rasterised, so animating `value` does not repaint the whole item on the
 * CPU every frame the way Canvas.requestPaint would.
 */
Item {
    id: root

    property real value: 0          // 0..1
    property string label: ""
    property color accent: Glass.accent
    property int thickness: 5

    implicitWidth: 78
    implicitHeight: 78

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Track
        ShapePath {
            strokeColor: Glass.glassRaised
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.thickness) / 2
                radiusY: (root.height - root.thickness) / 2
                startAngle: -90
                sweepAngle: 360
            }
        }

        // Value
        ShapePath {
            strokeColor: root.accent
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: arc

                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.thickness) / 2
                radiusY: (root.height - root.thickness) / 2
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(1, root.value))

                Behavior on sweepAngle {
                    Anim {
                        type: Anim.Standard
                    }
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        BarText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: Glass.textGlass
            pixelSize: Glass.fontTitle
        }

    }
}
