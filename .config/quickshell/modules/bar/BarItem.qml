import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/modules/common"

/**
 * The base every bar module sits in. Mirrors the shared rule in Glass.css:
 *
 *   padding: 3px 8px;
 *   border-radius: 10px;
 *   background-color: transparent;
 *   text-shadow: 0 1px 3px rgba(0, 0, 0, 0.55);
 *   transition: background-color .18s, color .18s, padding .18s;
 *
 * and the hover lift that follows it (@ui-hover, colourless by design).
 *
 * The text-shadow is NOT decoration - Glass.css calls it out as load-bearing.
 * Modules sit directly on the glass with no fill of their own, so without the
 * shadow the bar becomes unreadable over a pale wallpaper. Anything that gains
 * an opaque fill of its own turns it back off via `shadowed: false`.
 */
Rectangle {
    id: root

    default property alias content: row.data
    /// Text/icon colour for children that opt in.
    property color fg: Glass.textGlass
    /// Drop the legibility shadow - only for modules with their own fill.
    property bool shadowed: true
    /// Show the hover lift. Off for inert things like separators.
    property bool interactive: true
    /// Whether THIS item handles clicks/scroll itself. Turn off for modules
    /// that contain their own clickable children (the tray), or the TapHandler
    /// here takes an exclusive grab on release and swallows the child's click.
    property bool acceptsInput: true
    property alias spacing: row.spacing
    property alias containsMouse: hover.hovered

    /// Detail panel shown on hover, caelestia-style. Null = no popout.
    property Component popout: null
    /// Identity for the popout manager; defaults to the QML type name.
    property string popoutId: ""

    signal clicked(var button)
    signal scrolled(int delta)

    readonly property string _pid: popoutId !== "" ? popoutId : `${root}`

    // QsWindow.window is null during construction and only resolves once the
    // window is realised, so the screen is read lazily at open time rather
    // than captured here.
    function _screen() {
        return root.QsWindow.window?.screen ?? null;
    }

    Component.onCompleted: {
        if (popout)
            PopoutState.register(_pid, root, popout, _screen);
    }

    Component.onDestruction: {
        if (popout)
            PopoutState.unregister(_pid);
    }

    onContainsMouseChanged: {
        if (!popout)
            return;
        if (containsMouse)
            PopoutState.request(_pid, root, popout, _screen());
        else
            PopoutState.release(_pid);
    }

    // Rounded to even so `anchors.centerIn` never lands the text on a half
    // pixel - the thing that makes Qt text look soft next to pango's.
    implicitWidth: 2 * Math.ceil((row.implicitWidth + Glass.itemPaddingH * 2) / 2)
    implicitHeight: 2 * Math.ceil((row.implicitHeight + Glass.itemPaddingV * 2) / 2)
    Layout.alignment: Qt.AlignVCenter

    radius: Glass.itemRadius
    color: interactive && hover.hovered ? Glass.uiHover : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Glass.animFast
            easing.type: Easing.OutQuad
        }
    }

    HoverHandler {
        id: hover
    }

    TapHandler {
        enabled: root.acceptsInput
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onSingleTapped: eventPoint => root.clicked(eventPoint.event?.button ?? Qt.LeftButton)
    }

    WheelHandler {
        enabled: root.acceptsInput
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.scrolled(event.angleDelta.y)
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Glass.barSpacing
    }
}
