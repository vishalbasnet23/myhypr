import QtQuick
import "root:/modules/common"

/**
 * The drawer wrapper every panel is built on.
 *
 * Slide semantics, from the brief:
 *
 *   offsetScale  0 = fully on screen, 1 = fully off its edge
 *   the panel translates by (size + 5) * offsetScale along `edge`
 *
 * IMPORTANT - why the background does not fade:
 *
 * The Hyprland layer rule carries `ignore_alpha 0.10`, meaning pixels below
 * 10% alpha are skipped by the blur. If the panel background faded out, it
 * would cross that threshold partway through the animation and the blur would
 * snap off - a visible pop mid-close. So the background stays at full opacity
 * for the whole slide and only leaves the screen by moving. Content fades,
 * because content sits above the blurred surface and is unaffected by it.
 *
 * (Same reasoning caelestia uses; the threshold is what forces it.)
 */
Item {
    id: root

    /// "left" | "right" | "top" | "bottom"
    property string edge: "left"
    /// Driven by the owning panel from ShellState.
    property bool shouldBeActive: false
    /// Motion type for the slide.
    property int animType: Anim.DefaultSpatial

    property real offsetScale: shouldBeActive ? 0 : 1

    readonly property bool horizontal: edge === "left" || edge === "right"
    readonly property real travel: (horizontal ? implicitWidth : implicitHeight) + 5

    /// True while any part of the panel is on screen - drives the Loader.
    readonly property bool onScreen: offsetScale < 1

    visible: onScreen

    Behavior on offsetScale {
        Anim {
            type: root.animType
        }
    }

    // Size changes animate too, so a launcher growing with its result list or
    // a notification stack reflowing moves rather than jumps.
    Behavior on implicitWidth {
        enabled: root.onScreen
        Anim {
            type: Anim.Emphasized
        }
    }

    Behavior on implicitHeight {
        enabled: root.onScreen
        Anim {
            type: Anim.Emphasized
        }
    }

    transform: Translate {
        x: root.edge === "left" ? -root.travel * root.offsetScale : root.edge === "right" ? root.travel * root.offsetScale : 0
        y: root.edge === "top" ? -root.travel * root.offsetScale : root.edge === "bottom" ? root.travel * root.offsetScale : 0
    }
}
