import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "root:/modules/common"
import ".."

/**
 * waybar tray: { "icon-size": 20, "spacing": 4 }
 *
 * acceptsInput is false because each icon owns its own MouseArea. BarItem's
 * TapHandler would otherwise take an exclusive grab on release and swallow the
 * click before the icon ever saw it - which is why the icons rendered fine but
 * did nothing.
 */
BarItem {
    id: root

    interactive: false
    acceptsInput: false
    spacing: 4

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: entry

            required property SystemTrayItem modelData

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 20
            implicitHeight: 20

            IconImage {
                id: icon

                anchors.fill: parent
                source: entry.modelData.icon
                asynchronous: true
            }

            MouseArea {
                anchors.fill: parent
                // A 20px target is small; widen the hit area without moving
                // the icon itself.
                anchors.margins: -2
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    const item = entry.modelData;
                    // Menu-only items expose no activate action at all, so a
                    // left click on one must open the menu or nothing happens.
                    if (mouse.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu) {
                            // display() takes the WINDOW, not an Item - passing
                            // the delegate fails silently. relativeX/Y are in
                            // WINDOW coordinates too, so the delegate's own x
                            // (its offset inside the tray's RowLayout, ~20px)
                            // put every menu at the far left of a full-width
                            // bar. mapToItem(null, …) converts to the window
                            // space display() actually wants.
                            const p = entry.mapToItem(null, entry.width / 2, entry.height);
                            item.display(QsWindow.window, Math.round(p.x), Math.round(p.y));
                        }
                    } else if (mouse.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else {
                        item.activate();
                    }
                }

                onWheel: wheel => entry.modelData.scroll(wheel.angleDelta.y, false)
            }
        }
    }
}
