pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.modules.bar as Bar

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    readonly property real borderThickness: win.contentItem.Config.border.thickness
    readonly property real clampedThickness: win.contentItem.Config.border.clampedThickness

    x: clampedThickness + win.dragMaskPadding
    y: bar.clampedHeight + win.dragMaskPadding
    width: win.width - clampedThickness * 2 - win.dragMaskPadding * 2
    height: win.height - bar.clampedHeight - clampedThickness - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        x: 0
        width: panel.width * (1 - root.panels.dashboard.offsetScale) + root.borderThickness
    }

    // mydots: left-edge dashboard hotspot, 20px wide and at least 240px tall
    // (Interactions.hotspotMinHeight). The R above follows the panel, which is
    // 0px tall while closed, so with border thickness 0 the only input left at
    // the edge was a 2px strip: fine against a physical screen edge, skipped
    // entirely by a cursor crossing into a neighbouring monitor.
    Region {
        readonly property Item panel: root.panels.dashboard
        readonly property real h: Math.max(panel.height, 240)

        x: 0
        y: panel.y + panel.height / 2 - h / 2 + root.borderThickness + root.bar.implicitHeight
        width: 20
        height: h
        intersection: Intersection.Subtract
    }

    R {
        panel: root.panels.launcher
        y: root.win.height - height
        height: panel.height * (1 - root.panels.launcher.offsetScale) + root.borderThickness
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness + sidebarRegion.width
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.win.width - width
        width: panel.width * (1 - root.panels.sidebar.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.osdWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.osd.offsetScale) + root.borderThickness + sessionRegion.width
    }

    R {
        panel: root.panels.notifications
        y: root.bar.implicitHeight
        height: panel.height + root.borderThickness
    }

    R {
        panel: root.panels.utilities
        y: root.win.height - height
        height: panel.height * (1 - root.panels.utilities.offsetScale) + root.borderThickness
    }

    // Covers the full sidebar+utilities footprint as one unbroken rectangle whenever
    // either is opening, so the independently-computed sidebarRegion/utilities R above
    // (which meet at a seam when both are shown merged) can't leave a sub-pixel gap in
    // the input mask at that boundary for the pointer to fall through.
    Region {
        id: mergedSidebarUtilitiesRegion

        readonly property real openAmount: Math.max(1 - root.panels.utilities.offsetScale, 1 - root.panels.sidebar.offsetScale)

        x: root.win.width - Math.max(root.panels.sidebar.width, root.panels.utilities.width) - root.borderThickness
        y: root.panels.sidebar.y + root.borderThickness + root.bar.implicitHeight
        width: Math.max(root.panels.sidebar.width, root.panels.utilities.width) + root.borderThickness
        height: (root.win.height - y) * openAmount
        intersection: Intersection.Subtract
    }

    R {
        panel: root.panels.popoutsWrapper
        width: panel.width * (1 - root.panels.popoutsWrapper.offsetScale)
    }

    component R: Region {
        required property Item panel

        x: panel.x
        y: panel.y + root.borderThickness + root.bar.implicitHeight
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}
