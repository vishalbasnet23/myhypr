import QtQuick
import "root:/modules/common"

/**
 * The shell's NumberAnimation. Pick a motion type; duration and easing come
 * from Motion.qml together so they can never drift apart.
 *
 *   Behavior on offsetScale { Anim {} }                    // DefaultSpatial
 *   Behavior on opacity     { Anim { type: Anim.DefaultEffects } }
 *
 * Spatial types are for geometry - offsets, sizes, positions. Effects types
 * are for opacity and anything that must not overshoot past 1.0.
 */
NumberAnimation {
    id: root

    enum Type {
        DefaultSpatial = 0,
        FastSpatial,
        SlowSpatial,
        Emphasized,
        Standard,
        DefaultEffects,
        SlowEffects
    }

    property int type: Anim.DefaultSpatial

    duration: {
        // §6: reduced motion collapses everything to one short fade.
        if (Motion.reducedMotion)
            return Motion.reducedDuration;
        switch (root.type) {
        case Anim.FastSpatial:
            return Motion.scaled(Motion.durations.fastSpatial);
        case Anim.SlowSpatial:
            return Motion.scaled(Motion.durations.slowSpatial);
        case Anim.Emphasized:
            return Motion.scaled(Motion.durations.emphasized);
        case Anim.Standard:
            return Motion.scaled(Motion.durations.standard);
        case Anim.DefaultEffects:
            return Motion.scaled(Motion.durations.defaultEffects);
        case Anim.SlowEffects:
            return Motion.scaled(Motion.durations.slowEffects);
        default:
            return Motion.scaled(Motion.durations.defaultSpatial);
        }
    }

    easing.type: Motion.reducedMotion ? Easing.OutQuad : Easing.BezierSpline
    easing.bezierCurve: {
        if (Motion.reducedMotion)
            return Motion.curves.standard;
        switch (root.type) {
        case Anim.FastSpatial:
            return Motion.curves.fastSpatial;
        case Anim.SlowSpatial:
            return Motion.curves.slowSpatial;
        case Anim.Emphasized:
            return Motion.curves.emphasized;
        case Anim.Standard:
            return Motion.curves.standard;
        case Anim.DefaultEffects:
            return Motion.curves.defaultEffects;
        case Anim.SlowEffects:
            return Motion.curves.slowEffects;
        default:
            return Motion.curves.defaultSpatial;
        }
    }
}
