pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import M3Shapes
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property int modelData
    required property int index
    required property int activeWsId
    required property int ws
    required property HyprlandMonitor monitor

    required property int displayType
    required property bool showWindows
    required property var iconRules
    property string activeLabel
    property string occupiedLabel
    property string label

    readonly property list<HyprlandToplevel> toplevels: Hypr.toplevelsForWs(ws, GlobalConfig.bar.workspaces.ignoredTags)
    readonly property bool isOccupied: toplevels.length > 0
    readonly property bool hasWindows: isOccupied && showWindows && Config.bar.workspaces.maxWindowIcons > 0
    readonly property bool focused: activeWsId === ws
    readonly property list<int> focusedShapeList: [MaterialShape.Square]

    readonly property var brailleDigits: ({
            1: "⠁", 2: "⠃", 3: "⠉", 4: "⠙", 5: "⠑", 6: "⠋", 7: "⠛", 8: "⠓", 9: "⠊"
        })
    readonly property color dimColour: Colours.light ? Colours.mutedLine : Colours.layer(Colours.palette.m3outlineVariant, 2)

    property color offMonitorColour: Colours.light ? Qt.alpha(Colours.palette.m3secondary, 0.25) : Colours.palette.m3outlineVariant
    readonly property bool onOtherMonitor: {
        if (Config.bar.workspaces.perMonitor)
            return false;
        const mon = Hypr.workspaces.values.find(w => w.id === ws)?.monitor;
        return !!(mon && mon !== monitor);
    }
    readonly property color fgColour: {
        if (onOtherMonitor)
            return offMonitorColour;
        if (Colours.light) {
            // Tinted hierarchy: pink focus, teal occupied, faint teal empty.
            // onSurface reads as plain gray-black on light bars.
            if (focused)
                return Colours.palette.m3primary;
            return isOccupied ? Colours.mutedText : Colours.mutedLine;
        }
        if (focused || isOccupied || Config.bar.workspaces.occupiedBg)
            return Colours.palette.m3onSurface;
        return Colours.layer(Colours.palette.m3outlineVariant, 2);
    }

    function updateShape(): void {
        const shape = indicator.item as MaterialShape;
        if (!shape)
            return;

        if (focused)
            shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else
            shape.shape = Qt.binding(() => MaterialShape.Square);
    }

    implicitWidth: layout.implicitWidth + (hasWindows ? Tokens.padding.extraSmall : 0)
    implicitHeight: Tokens.sizes.bar.innerWidth

    onFocusedChanged: updateShape()
    Component.onCompleted: updateShape()

    // -- extra (non-native) indicator styles, gated by WorkspaceExtra.style --

    Component {
        id: extraDotsComponent

        Rectangle {
            implicitWidth: root.focused ? 10 : 7
            implicitHeight: implicitWidth
            radius: implicitWidth / 2
            color: root.focused ? Colours.palette.m3primary : root.isOccupied ? root.fgColour : root.dimColour

            Behavior on implicitWidth {
                Anim {}
            }

            Behavior on color {
                CAnim {}
            }
        }
    }

    Component {
        id: extraPillComponent

        Rectangle {
            implicitHeight: Tokens.sizes.bar.innerWidth - Tokens.padding.small
            implicitWidth: root.focused ? label.implicitWidth + Tokens.padding.small * 2 : implicitHeight * 0.4
            radius: Tokens.rounding.full
            color: root.focused ? Colours.palette.m3primary : root.isOccupied ? root.dimColour : (Colours.light ? Colours.mutedLine : Colours.layer(Colours.palette.m3outlineVariant, 1))

            Behavior on implicitWidth {
                Anim {
                    easing: Tokens.anim.expressiveDefaultSpatial
                }
            }

            StyledText {
                id: label

                anchors.centerIn: parent
                opacity: root.focused ? 1 : 0
                text: root.ws
                color: Colours.palette.m3onPrimary
                font.family: Tokens.font.workspaces

                Behavior on opacity {
                    Anim {}
                }
            }
        }
    }

    Component {
        id: extraSegmentsComponent

        Row {
            id: segRow

            spacing: 2
            readonly property int chips: Math.max(root.toplevels.length, root.focused ? 1 : 0)

            Repeater {
                model: segRow.chips

                delegate: Rectangle {
                    id: chip

                    required property int index

                    width: 5
                    height: Tokens.sizes.bar.innerWidth - Tokens.padding.small
                    radius: 1
                    color: Qt.hsla(((root.ws * 47 + chip.index * 29) % 360) / 360, 0.45, root.focused ? 0.62 : 0.38, 1)
                    opacity: root.onOtherMonitor ? 0.4 : 1
                }
            }
        }
    }

    Component {
        id: extraTicksComponent

        Rectangle {
            readonly property int windows: root.toplevels.length

            implicitWidth: 4
            implicitHeight: Math.max(6, Math.min(Tokens.sizes.bar.innerWidth - Tokens.padding.small, 6 + windows * 6))
            radius: 2
            color: root.focused ? Colours.palette.m3primary : root.isOccupied ? root.fgColour : root.dimColour

            Behavior on implicitHeight {
                Anim {}
            }
        }
    }

    Component {
        id: extraBracketComponent

        StyledText {
            animate: true
            text: root.focused ? `[${root.ws}]` : String(root.ws)
            color: root.focused ? Colours.palette.m3primary : root.isOccupied ? root.fgColour : root.dimColour
            verticalAlignment: Qt.AlignVCenter
            font.family: Tokens.font.workspaces
        }
    }

    Component {
        id: extraBadgeComponent

        Item {
            implicitWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small
            implicitHeight: implicitWidth

            Rectangle {
                anchors.fill: parent
                radius: Tokens.rounding.small
                color: root.focused ? Colours.palette.m3primary : root.dimColour

                StyledText {
                    anchors.centerIn: parent
                    text: root.ws
                    color: root.focused ? Colours.palette.m3onPrimary : root.fgColour
                    font.family: Tokens.font.workspaces
                }
            }

            Rectangle {
                visible: root.toplevels.length > 1
                width: 11
                height: 11
                radius: 5.5
                color: Colours.palette.m3tertiary
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: -3
                anchors.rightMargin: -3

                StyledText {
                    anchors.centerIn: parent
                    text: root.toplevels.length
                    font.pixelSize: 8
                    color: Colours.palette.m3onTertiary
                }
            }
        }
    }

    Component {
        id: extraGlowComponent

        Item {
            implicitWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small
            implicitHeight: implicitWidth

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 1.8
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Colours.palette.m3primary
                opacity: 0
                visible: root.focused

                SequentialAnimation on opacity {
                    running: root.focused
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 0.55
                        to: 0
                        duration: 1400
                        easing.type: Easing.OutQuad
                    }
                }

                SequentialAnimation on scale {
                    running: root.focused
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 0.6
                        to: 1
                        duration: 1400
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: root.focused ? parent.width * 0.6 : parent.width * 0.35
                height: width
                radius: width / 2
                color: root.focused ? Colours.palette.m3primary : root.isOccupied ? root.fgColour : root.dimColour

                Behavior on width {
                    Anim {}
                }
            }
        }
    }

    Component {
        id: extraBrailleComponent

        StyledText {
            animate: true
            text: (root.focused ? "⠼" : "") + (root.brailleDigits[root.ws] ?? String(root.ws))
            color: root.focused ? Colours.palette.m3primary : root.isOccupied ? root.fgColour : root.dimColour
            verticalAlignment: Qt.AlignVCenter
            font.family: Tokens.font.workspaces
        }
    }

    Component {
        id: shapeComponent

        MaterialShape {
            implicitSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small

            color: root.fgColour
            scale: root.focused ? 2 / 3 : root.isOccupied ? 1 / 3 : 1 / 4

            animationEasing: Tokens.anim.expressiveDefaultSpatial
            animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * Tokens.anim.durations.scale

            Behavior on color {
                CAnim {}
            }

            Behavior on scale {
                Anim {}
            }
        }
    }

    Component {
        id: textComponent

        StyledText {
            animate: true
            text: {
                if (root.focused) {
                    const label = root.activeLabel;
                    if (label)
                        return label;
                }

                if (root.focused || root.isOccupied) {
                    const label = root.occupiedLabel;
                    if (label)
                        return label;
                }

                const label = root.label;
                if (label)
                    return label;

                const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
                const wsName = !ws || ws.name == root.ws ? root.ws : Hypr.trimWsName(ws.name)[0];

                const capitalisation = Config.bar.workspaces.capitalisation;
                if (capitalisation === BarWorkspaceCapitalisation.Upper)
                    return String(wsName).toUpperCase();
                else if (capitalisation === BarWorkspaceCapitalisation.Lower)
                    return String(wsName).toLowerCase();
                return wsName;
            }
            color: root.fgColour
            verticalAlignment: Qt.AlignVCenter
            font.family: Tokens.font.workspaces
        }
    }

    Component {
        id: iconComponent

        MaterialIcon {
            fill: 1
            grade: 25
            text: iconCacher.icon
            color: root.fgColour
            verticalAlignment: Qt.AlignVCenter

            WsIconCacher {
                id: iconCacher
            }
        }
    }

    Component {
        id: iconLoaderComponent

        Loader {
            sourceComponent: loaderIconCacher.icon ? iconComponent : textComponent

            WsIconCacher {
                id: loaderIconCacher
            }
        }
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        spacing: 0

        Loader {
            id: indicator

            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.preferredWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small
            sourceComponent: {
                switch (WorkspaceExtra.style) {
                case "dots":
                    return extraDotsComponent;
                case "pill":
                    return extraPillComponent;
                case "segments":
                    return extraSegmentsComponent;
                case "ticks":
                    return extraTicksComponent;
                case "bracket":
                    return extraBracketComponent;
                case "badge":
                    return extraBadgeComponent;
                case "glow":
                    return extraGlowComponent;
                case "braille":
                    return extraBrailleComponent;
                }

                if (root.displayType === BarWorkspaceDisplay.Icons)
                    return iconLoaderComponent;
                if (root.displayType === BarWorkspaceDisplay.Text)
                    return textComponent;
                return shapeComponent;
            }

            onItemChanged: root.updateShape()
        }

        Loader {
            id: windows

            asynchronous: true

            Layout.fillWidth: true
            Layout.topMargin: -Tokens.spacing.extraSmall / 2
            Layout.preferredHeight: root.hasWindows && item ? (item as LazyListView).layoutHeight : 0

            visible: active
            active: root.showWindows && Config.bar.workspaces.maxWindowIcons > 0

            sourceComponent: LazyListView {
                spacing: 0
                implicitHeight: contentHeight
                cullDelegates: false
                removeDuration: Tokens.anim.durations.expressiveDefaultEffects

                model: ScriptModel {
                    values: {
                        const windows = root.toplevels;
                        const maxIcons = root.Config.bar.workspaces.maxWindowIcons;
                        return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                    }
                }

                delegate: MaterialIcon {
                    id: win

                    required property var modelData
                    required property int index // Needed, LazyListView will fail to set it if it doesn't exist

                    grade: 0
                    horizontalAlignment: Text.AlignHCenter
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: root.onOtherMonitor ? root.offMonitorColour : Colours.palette.m3onSurfaceVariant

                    opacity: LazyListView.adding || LazyListView.removing ? 0 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on y {
                        Anim {}
                    }
                }
            }
        }
    }

    component WsIconCacher: QtObject {
        id: cacher

        property string name
        readonly property string icon: Icons.matchIconRuleList(Hypr.trimWsName(name), root.iconRules)
        readonly property HyprlandWorkspace wsObj: Hypr.workspaces.values.find(w => w.id === root.ws) ?? null

        readonly property Connections conn: Connections {
            function onNameChanged(): void {
                cacher.updateName();
            }

            target: cacher.wsObj
        }

        function updateName(): void {
            if (wsObj)
                name = wsObj.name;
        }

        onWsObjChanged: updateName()
        Component.onCompleted: updateName()
    }
}
