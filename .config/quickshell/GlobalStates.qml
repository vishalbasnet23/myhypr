import "root:/modules/common/"
import QtQuick
import Quickshell
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool overviewOpen: false
    property bool mediaControlsOpen: false
    property bool mediaPinned: false      // click-to-pin, survives hover-out
    property bool mediaHoverSource: false // pointer is on the bar pill
    property bool mediaHoverPopup: false  // pointer is on the popup itself
}