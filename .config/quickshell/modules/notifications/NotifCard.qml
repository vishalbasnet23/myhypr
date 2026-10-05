import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "root:/modules/common"
import "root:/modules/bar"

/**
 * One notification.
 *
 * Follows swaync/style.css: a card on the glass with a 2px urgency strip down
 * the LEFT edge - the same motif as a selected rofi row - rather than a
 * coloured background. Urgency colours match the CSS:
 *   low      teal      normal  @sel (white)    critical  red
 */
Rectangle {
    id: root

    required property var notif
    /// Popup mode gets the darker free-floating fill; in the centre the panel
    /// behind it already provides a surface.
    property bool popup: false

    signal dismissed

    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property bool low: notif?.urgency === NotificationUrgency.Low
    readonly property color strip: critical ? Glass.critical : low ? Glass.ok : Glass.sel

    implicitHeight: body.implicitHeight + Glass.cardPadding * 2
    // §5 nested corners: inner = outer - padding.
    radius: popup ? Glass.pillRadius : Glass.panelRadius - Glass.panelPadding
    // §2: a popup IS the surface, so it keeps the glass border. Inside the
    // centre it is an inner card - card layer, NO border.
    color: popup ? Glass.panelSurface : Glass.cardLayer
    border.width: popup ? 1 : 0
    border.color: Glass.glassBorder

    // The urgency strip.
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 6
        width: 2
        radius: 1
        color: root.strip
    }

    RowLayout {
        id: body

        anchors.fill: parent
        anchors.leftMargin: Glass.panelPadding
        anchors.rightMargin: Glass.cardPadding
        anchors.topMargin: Glass.cardPadding
        anchors.bottomMargin: Glass.cardPadding
        spacing: Glass.cardPadding

        // App icon, or the notification's own image when it supplies one.
        IconImage {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 34      // swaync notification-icon-size
            Layout.preferredHeight: 34
            source: {
                const img = root.notif?.image ?? "";
                if (img !== "")
                    return img;
                const icon = root.notif?.appIcon ?? "";
                return icon !== "" ? Quickshell.iconPath(icon, true) : "";
            }
            visible: source !== ""
            asynchronous: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                BarText {
                    text: root.notif?.appName ?? ""
                    color: Glass.textDim
                    pixelSize: Glass.fontMeta
                    shadowed: false
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Close affordance, mirroring swaync's per-notification button.
                Rectangle {
                    // §8: 32x32 minimum hit target, drawn smaller.
                    implicitWidth: Glass.hitTarget
                    implicitHeight: Glass.hitTarget
                    radius: width / 2
                    color: closeMa.containsMouse ? Qt.rgba(1, 0.09, 0.27, 0.25) : "transparent"

                    BarText {
                        anchors.centerIn: parent
                        text: "×"
                        color: closeMa.containsMouse ? Glass.maroon : Glass.textDim
                        shadowed: false
                    }

                    MouseArea {
                        id: closeMa

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissed()
                    }
                }
            }

            BarText {
                text: root.notif?.summary ?? ""
                color: Glass.textGlass
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            BarText {
                text: root.notif?.body ?? ""
                color: Glass.textDim
                pixelSize: Glass.fontMeta
                shadowed: false
                wrapMode: Text.WordWrap
                visible: text !== ""
                Layout.fillWidth: true
                // §10: body is 2 lines maximum. The centre shows more.
                maximumLineCount: root.popup ? 2 : 12
                elide: Text.ElideRight
            }

            // Actions the app offered.
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 6
                visible: (root.notif?.actions?.length ?? 0) > 0

                Repeater {
                    model: root.notif?.actions ?? []

                    delegate: Rectangle {
                        required property var modelData

                        implicitWidth: actionLabel.implicitWidth + 16
                        implicitHeight: 22
                        radius: Glass.itemRadius
                        color: actionMa.containsMouse ? Glass.uiHover : Glass.glassRaised

                        BarText {
                            id: actionLabel

                            anchors.centerIn: parent
                            text: modelData.text
                            color: Glass.textGlass
                            pixelSize: Glass.fontMeta
                            shadowed: false
                        }

                        MouseArea {
                            id: actionMa

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                modelData.invoke();
                                root.dismissed();
                            }
                        }
                    }
                }
            }
        }
    }

    // swaync: "hide-on-action": true - clicking the body dismisses.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.dismissed()
    }
}
