import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/modules/common"
import "root:/modules/notifications"
import "root:/services"
import ".."

/**
 * Replaces waybar's group/notify drawer.
 *
 * The drawer revealed two icon-only buttons (pacupdate, cycle_wall) whose
 * meaning lived in tooltips. As a popout they become labelled actions with
 * their mouse-button bindings written out, which is the part of
 * "Left Click: Wallpaper Menu / Middle: Random / Right: Styles Menu" that
 * nobody could remember.
 */
ColumnLayout {
    id: root

    readonly property string home: Quickshell.env("HOME")

    spacing: 8
    // Layouts clobber implicitWidth, so the panel reads this instead.
    property int preferredWidth: 330

    PopoutHeader {
        text: "Notifications"
    }

    PopoutRow {
        label: "Unread"
        icon: "󰂚"
        value: `${Notifs.count}`
    }

    PopoutRow {
        label: "Do not disturb"
        icon: Notifs.dnd ? "󰂛" : "󰂚"
        value: Notifs.dnd ? "on" : "off"
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Glass.glassBorder
    }

    Action {
        glyph: "󰂚"
        title: "Notification centre"
        hint: "toggle panel · right-click for DND"
        onActivated: button => button === Qt.RightButton ? Notifs.toggleDnd() : NotifCentre.toggle()
    }

    Action {
        glyph: " 󰁈 "
        title: "System updates"
        hint: "open update terminal"
        onActivated: Quickshell.execDetached(["bash", `${root.home}/.config/hypr/UserScripts/PacmanUpdateTerminal.sh`])
    }

    Action {
        glyph: " "
        title: "Wallpaper"
        hint: "left menu · middle random · right styles"
        onActivated: button => {
            if (button === Qt.RightButton)
                Quickshell.execDetached(["bash", `${root.home}/.config/hypr/scripts/WaybarStyles.sh`]);
            else if (button === Qt.MiddleButton)
                Quickshell.execDetached(["bash", `${root.home}/.config/hypr/UserScripts/WallpaperRandom.sh`]);
            else
                Quickshell.execDetached(["bash", `${root.home}/.config/hypr/UserScripts/WallpaperSelect.sh`]);
        }
    }

    component Action: Rectangle {
        id: action

        required property string glyph
        required property string title
        property string hint: ""

        signal activated(var button)

        Layout.fillWidth: true
        implicitHeight: col.implicitHeight + 12
        radius: Glass.itemRadius
        color: ma.containsMouse ? Glass.uiHover : "transparent"

        Behavior on color {
            CAnim {}
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 10

            BarText {
                text: action.glyph
                color: Glass.textGlass
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 18
            }

            ColumnLayout {
                id: col

                spacing: 1
                Layout.fillWidth: true

                BarText {
                    text: action.title
                    color: Glass.textGlass
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                BarText {
                    text: action.hint
                    color: Glass.textDim
                    pixelSize: Glass.fontMeta
                    visible: action.hint !== ""
                    // The panel has a fixed width, so a long hint must shrink
                    // rather than run past the glass edge.
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: ma

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => action.activated(mouse.button)
        }
    }
}
