pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/**
 * Motion tokens. Every duration and curve in the shell comes from here - no
 * literal timings in panels or widgets.
 *
 * Curves are Qt BezierSpline control points: each segment is x1,y1,x2,y2,x3,y3
 * with the final pair always 1,1. The spatial curves overshoot past y=1
 * (1.21, 1.67, 1.29) which is what gives panels their slight settle at the end
 * of a slide - that is deliberate, not a typo.
 *
 * Effects curves do NOT overshoot: opacity and colour past 1.0 would clip.
 */
Singleton {
    id: root

    /// Global speed control. 0.5 = twice as fast, 2 = half speed, 0 = instant.
    property real durationScale: 1.0

    /// DESIGN.md §6. Replaces every spatial animation with a 150ms fade,
    /// forces squash off and disables staggers.
    property bool reducedMotion: false
    readonly property int reducedDuration: 150

    /// Stagger budget: <=30ms per item, <=5 items (§6).
    readonly property int staggerStep: 30
    readonly property int staggerMax: 5

    function stagger(index) {
        if (root.reducedMotion)
            return 0;
        return Math.min(index, root.staggerMax) * root.staggerStep;
    }

    function scaled(ms) {
        return Math.round(ms * root.durationScale);
    }

    readonly property QtObject durations: QtObject {
        readonly property int defaultSpatial: 500
        readonly property int fastSpatial: 350
        readonly property int slowSpatial: 650
        readonly property int emphasized: 400
        readonly property int standard: 400
        readonly property int defaultEffects: 200
        readonly property int slowEffects: 300
    }

    readonly property QtObject curves: QtObject {
        readonly property list<real> defaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property list<real> fastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        readonly property list<real> slowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
        readonly property list<real> emphasized: [0.05, 0, 0.1333, 0.06, 0.1667, 0.4, 0.2083, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> defaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        readonly property list<real> slowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
    }

    // ---- squash and stretch (Step 4, optional) ----
    /// Master switch for the velocity deformation on panel backgrounds.
    property bool deformEnabled: false
    readonly property bool deformActive: deformEnabled && !reducedMotion
    /// Per-panel deform amounts, from the brief.
    readonly property QtObject deform: QtObject {
        readonly property real sidebar: 0.03
        readonly property real dashboard: 0.1
        readonly property real launcher: 0.1
        readonly property real session: 0.2
        readonly property real osd: 0.25
    }
    readonly property real deformMaxStretch: 0.35
    readonly property real springStiffness: 200
    readonly property real springDamping: 16
}
