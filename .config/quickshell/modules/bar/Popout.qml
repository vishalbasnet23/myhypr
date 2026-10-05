import QtQuick
import Quickshell
import "root:/modules/common"

/**
 * The dropdown panel that hangs beneath a bar module.
 *
 * Replaces waybar's drawer behaviour: instead of the group expanding sideways
 * and shoving its neighbours along, the module stays put and the detail opens
 * below it, the way caelestia's popouts do - but wearing the Vibrant Glass
 * treatment rather than Material You.
 *
 * Styled as GLASS, matching the bar's pills: same blur, hairline, radius and
 * lit top edge. The FILL differs - see Glass.panelSurface - because a pill sits
 * over the wallpaper while a popout hangs over arbitrary windows. That only reads correctly because
 * WindowRules.lua carries `blur_popups` for the quickshell:bar namespace -
 * a popup is a separate Wayland surface from the layer that owns it, so the
 * layer's own blur rule does NOT cover it. Without that rule this panel is
 * a washed-out rectangle.
 *
 * anchor.adjustment = SlideX keeps it on screen when the owning module sits
 * near a screen edge - without it, the power button's popout would hang off
 * the right of the display.
 */
PopupWindow {
    id: root

    required property var barWindow

    visible: PopoutState.open && PopoutState.screen === barWindow.screen && PopoutState.anchorItem !== null

    // anchor.window, not the deprecated parentWindow - without a window the
    // popup has nothing to position against and never maps.
    anchor.window: barWindow

    // Anchored to the ITEM. A rect-based anchor would let the popup travel
    // between icons (REFERENCE.md wants move-and-resize rather than
    // close-and-reopen), but anchor.rect resolved against the window's left
    // edge rather than the icon, putting every popout in the top-left corner.
    // Correct placement wins until that is sorted; size still animates.
    anchor.item: PopoutState.anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX
    anchor.margins.top: Glass.spaceXs

    color: "transparent"

    implicitWidth: Math.max(120, panel.implicitWidth)
    implicitHeight: panel.implicitHeight + caret.height

    // Caret pointing back up at the module that owns this popout.
    Canvas {
        id: caret

        width: 16
        height: 7
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        z: 2

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.beginPath();
            ctx.moveTo(0, height);
            ctx.lineTo(width / 2, 0);
            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fillStyle = Glass.panelSurface;
            ctx.fill();
            ctx.strokeStyle = Glass.glassBorder;
            ctx.lineWidth = 1;
            ctx.stroke();
        }
    }

    Rectangle {
        id: panel

        anchors.top: caret.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        // Follow the loader's REAL size, not its implicit one - the loader is
        // sized from the content's preferredWidth above.
        implicitWidth: loader.width + padding * 2
        implicitHeight: loader.height + padding * 2

        readonly property int padding: Glass.panelPadding

        color: Glass.panelSurface
        radius: Glass.panelRadius
        border.width: 1
        border.color: Glass.glassBorder

        // Same lit top edge as the bar pill.
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 1
            color: Glass.glassHighlight
        }

        HoverHandler {
            onHoveredChanged: hovered ? PopoutState.hold() : PopoutState.release("")
        }

        Loader {
            id: loader

            anchors.centerIn: parent
            sourceComponent: PopoutState.content

            // Layouts ignore an assigned implicitWidth, so content declares
            // `preferredWidth` and gets sized to it here. Reading implicitWidth
            // in the fallback would close a loop (implicitWidth <- item <-
            // width), so `desired` is resolved first and the fallback is only
            // reached by content that declares no width at all.
            readonly property int desired: (item && item.preferredWidth > 0) ? item.preferredWidth : 0
            width: desired > 0 ? desired : implicitWidth
            height: implicitHeight
        }
    }

    // Slide-and-fade in. The bar's own transitions are 0.18s (Glass.css), so
    // this uses the same curve family to feel like one system.
    Behavior on implicitHeight {
        Anim { type: Anim.DefaultEffects }
    }
}
