import QtQuick
import "root:/modules/common"

/**
 * Colour twin of Anim.qml. Defaults to DefaultEffects, because colour changes
 * are effects rather than motion - and because the spatial curves overshoot
 * past 1.0, which on a colour channel clips instead of settling.
 */
ColorAnimation {
    id: root

    property int type: Anim.DefaultEffects

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
        case Anim.SlowEffects:
            return Motion.scaled(Motion.durations.slowEffects);
        case Anim.DefaultSpatial:
            return Motion.scaled(Motion.durations.defaultSpatial);
        default:
            return Motion.scaled(Motion.durations.defaultEffects);
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
        case Anim.SlowEffects:
            return Motion.curves.slowEffects;
        case Anim.DefaultSpatial:
            return Motion.curves.defaultSpatial;
        default:
            return Motion.curves.defaultEffects;
        }
    }
}
